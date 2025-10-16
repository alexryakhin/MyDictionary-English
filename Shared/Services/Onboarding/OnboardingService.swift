//
//  OnboardingService.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import Foundation
import Combine

final class OnboardingService: ObservableObject {
    static let shared = OnboardingService()

    @Published var showOnboarding = false
    @Published var showBanner = false
    @Published var userProfile: UserOnboardingProfile?
    
    private let coreDataService = CoreDataService.shared
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        loadProfile()
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
    
    // MARK: - Device Language Detection
    
    func detectNativeLanguage() -> InputLanguage {
        let locale = Locale.current
        if let languageCode = locale.language.languageCode?.identifier,
           let language = InputLanguage(rawValue: languageCode) {
            return language
        }
        return .english
    }
}

