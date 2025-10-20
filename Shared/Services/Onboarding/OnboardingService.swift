//
//  OnboardingService.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import Foundation
import Combine
import CoreData
import CloudKit

final class OnboardingService: ObservableObject {
    static let shared = OnboardingService()

    @Published var showOnboarding = false
    @Published var showBanner = false
    @Published var userProfile: UserOnboardingProfile?
    @Published var isLoadingFromCloud: Bool = false
    @Published var cloudLoadingMessage: String = ""
    @Published var hasFoundCloudProfile: Bool = false
    
    private let coreDataService = CoreDataService.shared
    private let cloudKitService = CloudKitService.shared
    private let profileSyncManager = OnboardingProfileSyncManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        loadProfile()
        showOnboardingIfNeeded()
        // Only cleanup duplicates if we detect multiple profiles
        if debugProfileCount() > 1 {
            cleanupDuplicateProfiles()
        }
    }
    
    // MARK: - Profile Management
    
    func loadProfile() {
        if let entity = coreDataService.fetchUserProfile(),
           let profile = UserOnboardingProfile(from: entity) {
            self.userProfile = profile
        }
    }
    
    func saveProfile(_ profile: UserOnboardingProfile) throws {
        try profile.saveToCoreData()
        self.userProfile = profile
        
        // Sync to Firestore if user is authenticated
        if AuthenticationService.shared.authenticationState == .signedIn {
            Task {
                try? await profile.syncToFirestore()
            }
        }
    }
    
    func hasCompletedProfile() -> Bool {
        return coreDataService.hasUserProfile()
    }
    
    func deleteProfile() throws {
        try coreDataService.deleteUserProfile()
        self.userProfile = nil
    }

    func checkIfShouldShowBanner() {
        // Show banner if:
        // 1. User has completed basic onboarding (hasCompletedOnboarding = true)
        // 2. User doesn't have a COMPLETE profile (profile might exist but incomplete)

        let hasCompletedOnboarding = UDService.hasCompletedOnboarding

        // Check if profile is complete by checking all required fields
        let hasCompleteProfile: Bool
        if let entity = CoreDataService.shared.fetchUserProfile(),
           let profile = UserOnboardingProfile(from: entity) {
            // Profile is complete if all required fields are filled
            hasCompleteProfile = profile.isComplete
        } else {
            hasCompleteProfile = false
        }

        if hasCompletedOnboarding && !hasCompleteProfile {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
                self?.showBanner = true
                AnalyticsService.shared.logEvent(.personalizationBannerShown)
            }
        }
    }

    func showOnboardingIfNeeded() {
        let hasCompletedOnboarding = UDService.hasCompletedOnboarding
        let entity = CoreDataService.shared.fetchUserProfile()

        if hasCompletedOnboarding {
            checkIfShouldShowBanner()
        } else if entity == nil || entity?.isCompleted == false {
            showOnboarding = true
        }
    }
    
    // MARK: - iCloud Profile Check
    
    /// Checks for existing profile in iCloud with loading UI
    func checkForExistingProfileInCloud() async {
        // Don't check if already has completed onboarding locally
        if UDService.hasCompletedOnboarding {
            return
        }
        
        // Check if iCloud is available first
        let isAvailable = await cloudKitService.checkAvailabilityWithTimeout(timeout: 2.0)
        
        guard isAvailable else {
            // iCloud not available, use local check only
            await MainActor.run {
                self.isLoadingFromCloud = false
            }
            return
        }
        
        // Show loading UI
        await MainActor.run {
            self.isLoadingFromCloud = true
            self.cloudLoadingMessage = Loc.Onboarding.loadingFromIcloud
        }
        
        // Check for existing profile with timeout
        let profileExists = await profileSyncManager.checkForExistingProfile()
        
        await MainActor.run {
            self.isLoadingFromCloud = false
            
            if profileExists {
                // Profile found in iCloud, show welcome screen with Get Started button
                self.hasFoundCloudProfile = true
                self.showOnboarding = true
                self.loadProfile()
            } else {
                // No profile found, show normal onboarding
                self.hasFoundCloudProfile = false
                self.showOnboarding = !UDService.hasCompletedOnboarding
            }
        }
    }
    
    // MARK: - Duplicate Cleanup
    
    /// Cleans up any duplicate profiles in Core Data
    private func cleanupDuplicateProfiles() {
        let context = coreDataService.context
        let fetchRequest: NSFetchRequest<CDUserProfile> = CDUserProfile.fetchRequest()
        
        do {
            let allProfiles = try context.fetch(fetchRequest)
            
            if allProfiles.count > 1 {
                // Sort by lastUpdated (most recent first)
                let sortedProfiles = allProfiles.sorted { 
                    ($0.lastUpdated ?? Date.distantPast) > ($1.lastUpdated ?? Date.distantPast) 
                }
                
                // Keep the most recent one, delete all others
                for duplicate in sortedProfiles.dropFirst() {
                    context.delete(duplicate)
                }
                
                try context.save()
                logInfo("Cleaned up \(sortedProfiles.count - 1) duplicate profile(s)")
            }
        } catch {
            logError("Failed to cleanup duplicate profiles: \(error)")
        }
    }

    // MARK: - Cloud Profile Handling
    
    /// Called when user presses "Get Started" with existing cloud profile
    func proceedWithCloudProfile() {
        // Mark onboarding as completed
        UDService.hasCompletedOnboarding = true
        
        // Dismiss onboarding
        showOnboarding = false
        hasFoundCloudProfile = false
        
        // Apply profile settings if we have a loaded profile
        if let profile = userProfile {
            applyProfileSettings(profile)
        }
    }
    
    // MARK: - Production Methods
    
    /// Production-safe method to clean up duplicates (call this once to fix existing duplicates)
    func cleanupDuplicatesIfNeeded() async {
        let profileCount = debugProfileCount()
        if profileCount > 1 {
            logInfo("Found \(profileCount) profiles, cleaning up duplicates...")
            await profileSyncManager.cleanupAllDuplicates()
        }
    }
    
    /// Debug method to check how many profiles exist
    func debugProfileCount() -> Int {
        let context = coreDataService.context
        let fetchRequest: NSFetchRequest<CDUserProfile> = CDUserProfile.fetchRequest()
        
        do {
            let profiles = try context.fetch(fetchRequest)
            return profiles.count
        } catch {
            return 0
        }
    }

    // MARK: - Profile Data Helpers
    
    func applyProfileSettings(_ profile: UserOnboardingProfile) {
        // Apply notification settings
        if profile.enabledNotifications {
            UDService.dailyRemindersEnabled = true
            
            // Set notification time based on preferred study time
            let calendar = Calendar.current
            let hour = profile.preferredStudyTime.defaultNotificationHour
            if let time = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: Date()) {
                UDService.dailyRemindersTime = time
            }
        }
        
        // Apply practice settings based on weekly word goal
        let dailyGoal = profile.weeklyWordGoal / 7
        UDService.practiceItemCount = min(max(dailyGoal, 5), 50)
        
        // Set primary language filter if user has study languages
        if let primaryLanguage = profile.primaryLanguage {
            UDService.quizLanguageFilter = primaryLanguage.rawValue
        }
        
        // Store user name
        if !profile.userName.isEmpty {
            UDService.userNickname = profile.userName
        }
    }
}

