//
//  OnboardingFlow.ViewModel.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import Foundation
import SwiftUI

extension OnboardingFlow {
    final class ViewModel: ObservableObject {
        // MARK: - Published Properties

        @Published var navigationPath = NavigationPath()
        @Published var userName: String = ""
        @Published var selectedUserType: UserType?
        @Published var selectedAgeGroup: AgeGroup?
        @Published var selectedGoals: Set<LearningGoal> = []
        @Published var studyLanguages: [StudyLanguage] = []
        @Published var selectedInterests: Set<Interest> = []
        @Published var weeklyWordGoal: Int = 25
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
            logInfo("[OnboardingViewModel] init – isNewUser=\(isNewUser)")

            // Load existing profile data if available
            loadExistingProfile()
        }

        // MARK: - Navigation

        func navigate(to step: OnboardingFlow.Step) {
            // Save current state before navigating
            saveProgressiveProfile()
            logInfo("[OnboardingViewModel] navigate(to:) -> \(step)")
            navigationPath.append(step)
        }

        func goBack() {
            if !navigationPath.isEmpty {
                navigationPath.removeLast()
                logInfo("[OnboardingViewModel] goBack() -> pathCount=\(navigationPath.count)")
            }
        }

        // MARK: - Progressive Saving

        private func loadExistingProfile() {
            logInfo("[OnboardingViewModel] Attempting to load existing onboarding profile")
            guard let entity = CoreDataService.shared.fetchUserProfile(),
                  let profile = UserOnboardingProfile(from: entity) else {
                logInfo("[OnboardingViewModel] No persisted onboarding profile found")
                return
            }

            // Load all saved data
            self.userName = profile.userName
            self.selectedUserType = profile.userType
            self.selectedAgeGroup = profile.ageGroup
            self.selectedGoals = Set(profile.learningGoals)
            self.studyLanguages = profile.studyLanguages
            self.selectedInterests = Set(profile.interests)
            self.weeklyWordGoal = profile.weeklyWordGoal
            self.preferredStudyTime = profile.preferredStudyTime
            self.enabledNotifications = profile.enabledNotifications
            self.skippedPaywall = profile.skippedPaywall
            self.completedSignIn = profile.signedIn
            logSuccess("[OnboardingViewModel] Loaded profile id=\(profile.id) name='\(profile.userName)' goals=\(profile.learningGoals.count) languages=\(profile.studyLanguages.count)")
        }

        private func saveProgressiveProfile() {
            // Create a profile with current state (not completed yet)
            let profile = createProfile(isCompleted: false)

            if profile.userName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                logWarning("[OnboardingViewModel] Progressive save with empty userName")
            }
            if profile.studyLanguages.isEmpty {
                logWarning("[OnboardingViewModel] Progressive save with no study languages selected yet")
            }
            if profile.learningGoals.isEmpty {
                logWarning("[OnboardingViewModel] Progressive save with no learning goals selected yet")
            }

            // Save to Core Data without marking as completed
            if (try? onboardingService.saveProfile(profile)) != nil {
                logInfo("[OnboardingViewModel] Progressive profile saved id=\(profile.id) stepCount=\(navigationPath.count)")
            } else {
                logError("[OnboardingViewModel] Failed to save progressive profile id=\(profile.id)")
            }
        }

        // MARK: - Paywall

        func skipPaywall() {
            skippedPaywall = true
            logWarning("[OnboardingViewModel] Paywall skipped by user")
            AnalyticsService.shared.logEvent(.onboardingPaywallSkipped)
            navigate(to: .success)
        }

        func completeOnboarding() {
            isLoading = true
            logInfo("[OnboardingViewModel] completeOnboarding() started")

            Task { @MainActor in
                do {
                    // Get CloudKit record ID FIRST, before creating profile
                    let cloudKitRecordID = await OnboardingProfileSyncManager.shared.getCloudKitRecordID()
                    logInfo("[OnboardingViewModel] Obtained CloudKitRecordID: \(cloudKitRecordID ?? "nil")")
                    
                    // Create profile with CloudKit record ID
                    var profile = createProfile(isCompleted: true)
                    profile.cloudKitRecordID = cloudKitRecordID

                    // Save to Core Data (will auto-sync to CloudKit)
                    try onboardingService.saveProfile(profile)
                    logSuccess("[OnboardingViewModel] Final profile saved id=\(profile.id) name='\(profile.userName)' goals=\(profile.learningGoals.count) languages=\(profile.studyLanguages.count)")

                    // Apply settings
                    onboardingService.applyProfileSettings(profile)
                    logInfo("[OnboardingViewModel] Applied onboarding profile settings")

                    // Mark onboarding as completed
                    UDService.hasCompletedOnboarding = true
                    logSuccess("[OnboardingViewModel] Onboarding marked as completed")

                    // Dismiss banner and onboarding sheet
                    onboardingService.showBanner = false
                    onboardingService.showOnboarding = false
                    logInfo("[OnboardingViewModel] Dismissed onboarding UI")

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
                    logSuccess("[OnboardingViewModel] Completion analytics logged")

                    // Generate AI paywall content in background (only if needed)
                    Task {
                        await PaywallContentService.shared.forceCheckAndGenerateIfNeeded()
                        logInfo("[OnboardingViewModel] Triggered paywall content refresh post-completion")
                    }

                    isLoading = false
                    logSuccess("[OnboardingViewModel] completeOnboarding() finished successfully")
                } catch {
                    errorMessage = error.localizedDescription
                    isLoading = false
                    logError("[OnboardingViewModel] completeOnboarding() failed: \(error.localizedDescription)")
                }
            }
        }

        // MARK: - Profile Creation

        private func createProfile(isCompleted: Bool = false) -> UserOnboardingProfile {
            return UserOnboardingProfile(
                id: UUID(),
                cloudKitRecordID: .empty,
                userName: userName,
                userType: selectedUserType ?? .hobbyist,
                ageGroup: selectedAgeGroup ?? .adult,
                learningGoals: Array(selectedGoals),
                studyLanguages: studyLanguages,
                interests: Array(selectedInterests),
                weeklyWordGoal: weeklyWordGoal,
                preferredStudyTime: preferredStudyTime,
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
                logSuccess("[OnboardingViewModel] Added study language \(language.englishName) at level \(level.rawValue)")
            } else {
                logWarning("[OnboardingViewModel] Attempted to add duplicate study language \(language.englishName)")
            }
        }

        func removeStudyLanguage(id: UUID) {
            if let language = studyLanguages.first(where: { $0.id == id }) {
                studyLanguages.removeAll { $0.id == id }
                logInfo("[OnboardingViewModel] Removed study language \(language.language.rawValue)")
            } else {
                logWarning("[OnboardingViewModel] Attempted to remove missing study language id=\(id)")
            }
        }

        func updateStudyLanguageLevel(id: UUID, level: CEFRLevel) {
            if let index = studyLanguages.firstIndex(where: { $0.id == id }) {
                studyLanguages[index] = StudyLanguage(
                    id: id,
                    language: studyLanguages[index].language,
                    proficiencyLevel: level
                )
                logInfo("[OnboardingViewModel] Updated study language \(studyLanguages[index].language.rawValue) to level \(level.rawValue)")
            } else {
                logWarning("[OnboardingViewModel] Attempted to update missing study language id=\(id)")
            }
        }
    }
}
