//
//  OnboardingViewModel.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import Foundation
import SwiftUI

final class OnboardingViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var navigationPath = NavigationPath()
    @Published var userName: String = ""
    @Published var selectedUserType: UserType?
    @Published var selectedAgeGroup: AgeGroup?
    @Published var selectedGoals: Set<LearningGoal> = []
    @Published var studyLanguages: [StudyLanguage] = []
    @Published var nativeLanguage: InputLanguage = .english
    @Published var selectedInterests: Set<Interest> = []
    @Published var weeklyWordGoal: Int = 100
    @Published var preferredStudyTime: StudyTime = .evening
    @Published var enabledNotifications: Bool = false
    @Published var skippedPaywall: Bool = false
    @Published var completedSignIn: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // MARK: - Properties
    
    let isNewUser: Bool
    let onboardingService = OnboardingService.shared
    let subscriptionService = SubscriptionService.shared
    let authService = AuthenticationService.shared
    
    // MARK: - Initialization
    
    init(isNewUser: Bool) {
        self.isNewUser = isNewUser
        
        // Load existing profile data if available
        loadExistingProfile()
        
        // Auto-detect native language if not already set
        if nativeLanguage == .english && onboardingService.detectNativeLanguage() != .english {
            self.nativeLanguage = onboardingService.detectNativeLanguage()
        }
    }
    
    // MARK: - Navigation
    
    func navigate(to step: OnboardingStep) {
        // Save current state before navigating
        saveProgressiveProfile()
        navigationPath.append(step)
    }
    
    func goBack() {
        if !navigationPath.isEmpty {
            navigationPath.removeLast()
        }
    }
    
    // MARK: - Progressive Saving
    
    private func loadExistingProfile() {
        guard let entity = CoreDataService.shared.fetchUserProfile(),
              let profile = UserOnboardingProfile(from: entity) else {
            return
        }
        
        // Load all saved data
        self.userName = profile.userName
        self.selectedUserType = profile.userType
        self.selectedAgeGroup = profile.ageGroup
        self.selectedGoals = Set(profile.learningGoals)
        self.studyLanguages = profile.studyLanguages
        self.nativeLanguage = profile.nativeLanguage
        self.selectedInterests = Set(profile.interests)
        self.weeklyWordGoal = profile.weeklyWordGoal
        self.preferredStudyTime = profile.preferredStudyTime
        self.enabledNotifications = profile.enabledNotifications
        self.skippedPaywall = profile.skippedPaywall
        self.completedSignIn = profile.signedIn
    }
    
    private func saveProgressiveProfile() {
        // Create a profile with current state (not completed yet)
        let profile = createProfile(isCompleted: false)
        
        // Save to Core Data without marking as completed
        try? onboardingService.saveProfile(profile)
    }
    
    // MARK: - Paywall
    
    func skipPaywall() {
        skippedPaywall = true
        AnalyticsService.shared.logEvent(.onboardingPaywallSkipped)
    }
    
    func completeOnboarding() {
        isLoading = true
        
        Task { @MainActor in
            do {
                // Create profile (mark as completed)
                let profile = createProfile(isCompleted: true)
                
                // Save to Core Data
                try onboardingService.saveProfile(profile)
                
                // Apply settings
                onboardingService.applyProfileSettings(profile)
                
                // Mark onboarding as completed
                UDService.hasCompletedOnboarding = true
                
                // Dismiss banner and onboarding sheet
                onboardingService.showBanner = false
                onboardingService.showOnboarding = false

                // Log completion
                let profileData: [String: Any] = [
                    "userType": profile.userType.rawValue,
                    "ageGroup": profile.ageGroup.rawValue,
                    "goalCount": profile.learningGoals.count,
                    "languageCount": profile.studyLanguages.count,
                    "interestCount": profile.interests.count,
                    "weeklyGoal": profile.weeklyWordGoal,
                    "skippedPaywall": profile.skippedPaywall,
                    "enabledNotifications": profile.enabledNotifications,
                    "signedIn": profile.signedIn
                ]
                AnalyticsService.shared.logEvent(.onboardingCompleted, parameters: profileData)
                
                isLoading = false
            } catch {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }
    
    // MARK: - Profile Creation
    
    private func createProfile(isCompleted: Bool = false) -> UserOnboardingProfile {
        return UserOnboardingProfile(
            userName: userName.isEmpty ? "Friend" : userName,
            userType: selectedUserType ?? .hobbyist,
            ageGroup: selectedAgeGroup ?? .adult,
            learningGoals: Array(selectedGoals),
            studyLanguages: studyLanguages,
            interests: Array(selectedInterests),
            weeklyWordGoal: weeklyWordGoal,
            preferredStudyTime: preferredStudyTime,
            nativeLanguage: nativeLanguage,
            completedAt: Date(),
            isCompleted: isCompleted,
            skippedPaywall: skippedPaywall,
            enabledNotifications: enabledNotifications,
            signedIn: authService.authenticationState == .signedIn,
            lastUpdated: Date()
        )
    }
    
    // MARK: - Study Language Management
    
    func addStudyLanguage(language: InputLanguage, level: CEFRLevel) {
        let newLanguage = StudyLanguage(language: language, proficiencyLevel: level)
        if !studyLanguages.contains(where: { $0.language == language }) {
            studyLanguages.append(newLanguage)
        }
    }
    
    func removeStudyLanguage(id: UUID) {
        studyLanguages.removeAll { $0.id == id }
    }
    
    func updateStudyLanguageLevel(id: UUID, level: CEFRLevel) {
        if let index = studyLanguages.firstIndex(where: { $0.id == id }) {
            studyLanguages[index] = StudyLanguage(
                id: id,
                language: studyLanguages[index].language,
                proficiencyLevel: level
            )
        }
    }
    
}

