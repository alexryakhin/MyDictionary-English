//
//  LearningPreferencesView.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import SwiftUI
import Flow

struct LearningPreferencesView: View {
    @StateObject private var onboardingService = OnboardingService.shared
    @Environment(\.dismiss) private var dismiss

    @State private var currentProfile: UserOnboardingProfile?
    @State private var isLoading = false

    // Form state
    @State private var userName: String = ""
    @State private var userType: UserType = .student
    @State private var ageGroup: AgeGroup = .adult
    @State private var weeklyWordGoal: Int = 100
    @State private var preferredStudyTime: StudyTime = .morning
    @State private var learningGoals: [LearningGoal] = []
    @State private var studyLanguages: [StudyLanguage] = []
    @State private var interests: [Interest] = []
    @State private var enabledNotifications: Bool = false
    
    // Language selection
    @State private var selectedLanguageToAdd: InputLanguage?
    @State private var selectedLevel: CEFRLevel = .b1

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    if let profile = currentProfile {
                        // Profile Information
                        profileInfoSection(profile)

                        // Learning Goals
                        learningGoalsSection

                        // Study Languages
                        studyLanguagesSection

                        // Interests
                        interestsSection

                        // Study Settings
                        studySettingsSection

                    } else if isLoading {
                        ProgressView(Loc.Profile.loadingPreferences)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        Text(Loc.Profile.noProfileFound)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
            }
            .groupedBackground()
            .navigationTitle(Loc.Profile.learningPreferencesTitle)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Loc.Profile.cancel) {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(Loc.Profile.save) {
                        savePreferences()
                    }
                    .bold()
                    .disabled(isLoading)
                }
            }
        }
        .onAppear {
            loadCurrentProfile()
        }
        .sheet(item: $selectedLanguageToAdd) { language in
            OnboardingFlow.LanguageLevelPicker(
                language: language,
                selectedLevel: $selectedLevel,
                onSave: {
                    addStudyLanguage(language, proficiencyLevel: selectedLevel)
                    selectedLanguageToAdd = nil
                }
            )
        }
    }

    // MARK: - Profile Info Section

    @ViewBuilder
    private func profileInfoSection(_ profile: UserOnboardingProfile) -> some View {
        CustomSectionView(header: Loc.Profile.profileInformation, hPadding: .zero) {
            FormWithDivider {
                CellWrapper {
                    Text(Loc.Profile.name)
                        .font(.body)
                        .fontWeight(.medium)
                } trailingContent: {
                    Text(profile.userName.isEmpty ? Loc.Profile.notSet : profile.userName)
                        .font(.body)
                        .foregroundColor(.secondary)
                }

                CellWrapper {
                    Text(Loc.Profile.userType)
                        .font(.body)
                        .fontWeight(.medium)
                } trailingContent: {
                    HeaderButtonMenu(userType.displayName) {
                        Picker("User Type", selection: $userType) {
                            ForEach(UserType.allCases, id: \.self) { type in
                                Text(type.displayName).tag(type)
                            }
                        }
                        .pickerStyle(.inline)
                    }
                }

                CellWrapper {
                    Text(Loc.Profile.ageGroup)
                        .font(.body)
                        .fontWeight(.medium)
                } trailingContent: {
                    HeaderButtonMenu(ageGroup.displayName) {
                        Picker("Age Group", selection: $ageGroup) {
                            ForEach(AgeGroup.allCases, id: \.self) { group in
                                Text(group.displayName).tag(group)
                            }
                        }
                        .pickerStyle(.inline)
                    }
                }
            }
            .padding(.bottom, -12)
        }
    }

    // MARK: - Learning Goals Section

    private var learningGoalsSection: some View {
        CustomSectionView(header: Loc.Profile.learningGoals) {
            HFlow(alignment: .top, spacing: 8) {
                ForEach(LearningGoal.allCases, id: \.self) { goal in
                    TagView(
                        text: goal.displayName,
                        style: learningGoals.contains(goal) ? .selected : .regular
                    )
                    .onTap {
                        toggleLearningGoal(goal)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Study Languages Section

    private var studyLanguagesSection: some View {
        CustomSectionView(header: Loc.Profile.studyLanguages) {
            HFlow(alignment: .top, spacing: 8) {
                // Show current study languages
                ForEach(studyLanguages) { language in
                    TagView(text: language.displayName, style: .selected)
                        .contextMenu {
                            Button(role: .destructive) {
                                removeStudyLanguage(language)
                            } label: {
                                Label(Loc.Actions.delete, systemImage: "minus.circle.fill")
                            }
                            .tint(.red)
                        }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
         } trailingContent: {
             HeaderButtonMenu(Loc.Profile.addLanguage, size: .small, style: .borderedProminent) {
                 ForEach(availableLanguages, id: \.self) { inputLanguage in
                     Button(inputLanguage.displayName) {
                         selectedLanguageToAdd = inputLanguage
                     }
                 }
             }
         }
    }

    private var availableLanguages: [InputLanguage] {
        // Return languages that aren't already added
        let addedLanguageCodes = Set(studyLanguages.map { $0.language })
        return InputLanguage.allCases.filter { !addedLanguageCodes.contains($0) }
    }

    // MARK: - Interests Section

    private var interestsSection: some View {
        CustomSectionView(header: Loc.Profile.interests) {
            HFlow(alignment: .top, spacing: 8) {
                ForEach(Interest.allCases, id: \.self) { interest in
                    TagView(
                        text: interest.displayName,
                        style: interests.contains(interest) ? .selected : .regular
                    )
                    .onTap {
                        toggleInterest(interest)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Study Settings Section

    private var studySettingsSection: some View {
        CustomSectionView(header: Loc.Profile.studySettings, hPadding: .zero) {
            FormWithDivider {
                // Weekly Word Goal
                CellWrapper {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(Loc.Profile.weeklyWordGoal)
                            .font(.body)
                            .fontWeight(.medium)
                        Text("\(weeklyWordGoal) \(Loc.Profile.words)")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                } trailingContent: {
                    Stepper("", value: $weeklyWordGoal, in: 10...200, step: 10)
                }

                // Preferred Study Time
                CellWrapper {
                    Text(Loc.Profile.preferredStudyTime)
                        .font(.body)
                        .fontWeight(.medium)
                } trailingContent: {
                    HeaderButtonMenu(preferredStudyTime.displayName) {
                        Picker("Study Time", selection: $preferredStudyTime) {
                            ForEach(StudyTime.allCases, id: \.self) { time in
                                Text(time.displayName).tag(time)
                            }
                        }
                        .pickerStyle(.inline)
                    }
                }
            }
            .padding(.bottom, -12)
        }
    }

    // MARK: - Helper Methods

    private func loadCurrentProfile() {
        isLoading = true

        if let profile = onboardingService.userProfile {
            currentProfile = profile
            populateForm(with: profile)
        } else {
            // Try to load from Core Data
            if let entity = CoreDataService.shared.fetchUserProfile(),
               let profile = UserOnboardingProfile(from: entity) {
                currentProfile = profile
                populateForm(with: profile)
            }
        }

        isLoading = false
    }

    private func populateForm(with profile: UserOnboardingProfile) {
        userName = profile.userName
        userType = profile.userType
        ageGroup = profile.ageGroup
        weeklyWordGoal = profile.weeklyWordGoal
        preferredStudyTime = profile.preferredStudyTime
        learningGoals = profile.learningGoals
        studyLanguages = profile.studyLanguages
        interests = profile.interests
        enabledNotifications = profile.enabledNotifications
    }

    private func toggleLearningGoal(_ goal: LearningGoal) {
        if learningGoals.contains(goal) {
            learningGoals.removeAll { $0 == goal }
        } else {
            learningGoals.append(goal)
        }
    }

    private func addStudyLanguage(_ inputLanguage: InputLanguage, proficiencyLevel: CEFRLevel) {
        let newLanguage = StudyLanguage(language: inputLanguage, proficiencyLevel: proficiencyLevel)
        studyLanguages.append(newLanguage)
    }

    private func removeStudyLanguage(_ language: StudyLanguage) {
        studyLanguages.removeAll { $0.id == language.id }
    }

    private func toggleInterest(_ interest: Interest) {
        if interests.contains(interest) {
            interests.removeAll { $0 == interest }
        } else {
            interests.append(interest)
        }
    }

    private func savePreferences() {
        guard let profile = currentProfile else { return }

        isLoading = true

        // Create updated profile
        var updatedProfile = profile
        updatedProfile.userName = userName
        updatedProfile.userType = userType
        updatedProfile.ageGroup = ageGroup
        updatedProfile.weeklyWordGoal = weeklyWordGoal
        updatedProfile.preferredStudyTime = preferredStudyTime
        updatedProfile.learningGoals = learningGoals
        updatedProfile.studyLanguages = studyLanguages
        updatedProfile.interests = interests
        updatedProfile.enabledNotifications = enabledNotifications
        updatedProfile.lastUpdated = Date()

        do {
            try onboardingService.saveProfile(updatedProfile)
            onboardingService.applyProfileSettings(updatedProfile)
            dismiss()
        } catch {
            errorReceived(error)
        }

        isLoading = false
    }
}

#Preview {
    LearningPreferencesView()
}
