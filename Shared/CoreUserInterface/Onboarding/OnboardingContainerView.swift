//
//  OnboardingContainerView.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import SwiftUI
import Flow

// MARK: - Onboarding Step Enum

enum OnboardingStep: Hashable {
    case welcome
    case name
    case userType
    case ageGroup
    case goals
    case languages
    case nativeLanguage
    case interests
    case studyIntensity
    case studyTime
    case streak
    case notifications
    case paywall
    case signIn
    case success
    
    var stepNumber: Int {
        switch self {
        case .welcome: return 0
        case .name: return 1
        case .userType: return 2
        case .ageGroup: return 3
        case .goals: return 4
        case .languages: return 5
        case .nativeLanguage: return 6
        case .interests: return 7
        case .studyIntensity: return 8
        case .studyTime: return 9
        case .streak: return 10
        case .notifications: return 11
        case .paywall: return 12
        case .signIn: return 13
        case .success: return 14
        }
    }
}

struct OnboardingContainerView: View {
    @StateObject private var viewModel: OnboardingViewModel
    @Environment(\.dismiss) var dismiss
    
    init(isNewUser: Bool) {
        _viewModel = StateObject(wrappedValue: OnboardingViewModel(isNewUser: isNewUser))
    }
    
    var body: some View {
        NavigationStack(path: $viewModel.navigationPath) {
            // Initial screen (Welcome)
            OnboardingWelcomeView(viewModel: viewModel)
                .navigationBarTitleDisplayMode(.inline)
                .navigationDestination(for: OnboardingStep.self) { step in
                    stepView(for: step)
                        .navigationBarTitleDisplayMode(.inline)
                        .navigationBarBackButtonHidden(true)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarLeading) {
                                Button(action: viewModel.goBack) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "chevron.left")
                                        Text(Loc.Onboarding.back)
                                    }
                                }
                            }
                        }
                }
        }
        .interactiveDismissDisabled()
    }
    
    @ViewBuilder
    private func stepView(for step: OnboardingStep) -> some View {
        switch step {
        case .welcome:
            OnboardingWelcomeView(viewModel: viewModel)
        case .name:
            OnboardingNameView(viewModel: viewModel)
        case .userType:
            OnboardingUserTypeView(viewModel: viewModel)
        case .ageGroup:
            OnboardingAgeGroupView(viewModel: viewModel)
        case .goals:
            OnboardingGoalsView(viewModel: viewModel)
        case .languages:
            OnboardingLanguagesView(viewModel: viewModel)
        case .nativeLanguage:
            OnboardingNativeLanguageView(viewModel: viewModel)
        case .interests:
            OnboardingInterestsView(viewModel: viewModel)
        case .studyIntensity:
            OnboardingStudyIntensityView(viewModel: viewModel)
        case .studyTime:
            OnboardingStudyTimeView(viewModel: viewModel)
        case .streak:
            OnboardingStreakView(viewModel: viewModel)
        case .notifications:
            OnboardingNotificationsView(viewModel: viewModel)
        case .paywall:
            OnboardingPaywallView(viewModel: viewModel)
        case .signIn:
            OnboardingSignInView(viewModel: viewModel)
        case .success:
            OnboardingSuccessView(viewModel: viewModel)
        }
    }
}

// MARK: - Placeholder views for screens not yet fully implemented
// These should be replaced with actual implementations

struct OnboardingNativeLanguageView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @State private var searchText = ""
    
    var filteredLanguages: [InputLanguage] {
        if searchText.isEmpty {
            return InputLanguage.allCases
        }
        return InputLanguage.allCases.filter {
            $0.displayName.lowercased().contains(searchText.lowercased())
        }
    }
    
    var body: some View {
        VStack(spacing: 24) {
            Text(Loc.Onboarding.whatsYourNativeLanguage)
                .font(.title.bold())
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .padding(.top, 40)
            
            SearchBar(text: $searchText, placeholder: Loc.Onboarding.searchYourLanguage)
                .padding(.horizontal, 24)
            
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(filteredLanguages, id: \.self) { language in
                        Button(action: {
                            viewModel.nativeLanguage = language
                            viewModel.navigate(to: .interests)
                        }) {
                            HStack {
                                Text(language.displayName)
                                Spacer()
                                if viewModel.nativeLanguage == language {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.accentColor)
                                }
                            }
                            .padding()
                            .background(Color.gray.opacity(0.05))
                            .cornerRadius(12)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 24)
            }
        }
    }
}

struct OnboardingInterestsView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    
    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    var body: some View {
        VStack(spacing: 32) {
            VStack(spacing: 16) {
                Text(Loc.Onboarding.whatTopicsInterestYou)
                    .font(.title.bold())
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .padding(.top, 40)
                
                Text(Loc.Onboarding.select2To5Interests)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            ScrollView {
                HFlow(alignment: .top, spacing: 12) {
                    ForEach(Interest.allCases, id: \.self) { interest in
                        SelectableChip(
                            title: interest.displayName,
                            icon: interest.icon,
                            isSelected: viewModel.selectedInterests.contains(interest)
                        ) {
                            toggleInterest(interest)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
            }
            
            Spacer()
            
            ActionButton(Loc.Onboarding.continue) {
                viewModel.navigate(to: .studyIntensity)
            }
            .disabled(!(viewModel.selectedInterests.count >= 2 && viewModel.selectedInterests.count <= 5))
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
    }
    
    private func toggleInterest(_ interest: Interest) {
        if viewModel.selectedInterests.contains(interest) {
            viewModel.selectedInterests.remove(interest)
        } else if viewModel.selectedInterests.count < 5 {
            viewModel.selectedInterests.insert(interest)
        }
    }
}

struct OnboardingStudyIntensityView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    
    private let weeklyGoals = [50, 100, 200, 300]
    
    var body: some View {
        VStack(spacing: 32) {
            Text(Loc.Onboarding.howManyWordsPerWeek)
                .font(.title.bold())
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .padding(.top, 40)
            
            Spacer()
            
            Picker("Weekly Goal", selection: $viewModel.weeklyWordGoal) {
                ForEach(weeklyGoals, id: \.self) { goal in
                    Text(Loc.Onboarding.wordsPerWeek(goal))
                        .font(.caption)
                        .tag(goal)
                }
            }
            .pickerStyle(.wheel)
            .padding(.horizontal, 32)
            
            Text(Loc.Onboarding.estimatedDailyTime(viewModel.weeklyWordGoal / 7 * 2))
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            ActionButton(Loc.Onboarding.continue) {
                viewModel.navigate(to: .studyTime)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
    }
}

struct OnboardingStudyTimeView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    
    var body: some View {
        VStack(spacing: 32) {
            Text(Loc.Onboarding.whenDoYouPreferToStudy)
                .font(.title.bold())
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .padding(.top, 40)
            
            VStack(spacing: 16) {
                ForEach(StudyTime.allCases, id: \.self) { studyTime in
                    SelectableCard(
                        title: studyTime.displayName,
                        subtitle: studyTime.timeRange,
                        icon: studyTime.icon,
                        isSelected: viewModel.preferredStudyTime == studyTime
                    ) {
                        viewModel.preferredStudyTime = studyTime
                    }
                }
            }
            .padding(.horizontal, 24)
            
            Spacer()
            
            ActionButton(Loc.Onboarding.continue) {
                viewModel.navigate(to: .streak)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
    }
}

struct OnboardingStreakView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                Spacer()
                    .frame(height: 60)
                
                // Image
                Image(systemName: "flame.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.orange)
                
                // Title
                Text(Loc.Onboarding.buildYourLearningStreak)
                    .font(.title.bold())
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                
                // Subtitle
                Text(Loc.Onboarding.streakIntroMessage)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                
                Spacer()
                    .frame(height: 40)
            }
            .frame(maxWidth: .infinity)
        }
        .safeAreaInset(edge: .bottom) {
            ActionButton(Loc.Onboarding.soundsGreat) {
                viewModel.navigate(to: .notifications)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
        }
    }
}

struct OnboardingNotificationsView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                Spacer()
                    .frame(height: 60)
                
                // Image
                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.accentColor)
                
                // Title
                Text(Loc.Onboarding.stayOnTrackWithReminders)
                    .font(.title.bold())
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                
                Spacer()
                    .frame(height: 40)
            }
            .frame(maxWidth: .infinity)
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 12) {
                AsyncActionButton(Loc.Onboarding.enableNotifications) {
                    await NotificationService.shared.requestPermission()
                    await MainActor.run {
                        viewModel.enabledNotifications = true
                        if viewModel.subscriptionService.isProUser {
                            viewModel.navigate(to: .signIn)
                        } else {
                            viewModel.navigate(to: .paywall)
                        }
                    }
                }

                Button(Loc.Onboarding.maybeLater) {
                    viewModel.enabledNotifications = false
                    if viewModel.subscriptionService.isProUser {
                        viewModel.navigate(to: .signIn)
                    } else {
                        viewModel.navigate(to: .paywall)
                    }
                }
                .foregroundColor(.secondary)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
        }
    }
}

struct OnboardingPaywallView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer()
                    .frame(height: 40)
                
                // Image
                Image(systemName: "crown.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .foregroundColor(.yellow)
                
                // Title
                Text(Loc.Onboarding.unlockFullLearningPotential)
                    .font(.title.bold())
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                
                // Subtitle
                Text(Loc.Onboarding.start7DayFreeTrial)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                // Content
                VStack(alignment: .leading, spacing: 16) {
                    FeatureRow(icon: "star.fill", text: Loc.Onboarding.unlimitedWordsAndQuizzes)
                    FeatureRow(icon: "icloud.fill", text: Loc.Onboarding.crossDeviceSync)
                    FeatureRow(icon: "sparkles", text: Loc.Onboarding.prioritySupport)
                }
                .padding(.horizontal, 32)
                
                Spacer()
                    .frame(height: 40)
            }
            .frame(maxWidth: .infinity)
        }
        .safeAreaInset(edge: .bottom) {
            ActionButton(Loc.Onboarding.startFreeTrial) {
                // TODO: Trigger RevenueCat purchase
                if viewModel.authService.authenticationState == .signedIn {
                    viewModel.navigate(to: .success)
                } else {
                    viewModel.navigate(to: .signIn)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(Loc.Onboarding.skip) {
                    viewModel.skipPaywall()
                    if viewModel.authService.authenticationState == .signedIn {
                        viewModel.navigate(to: .success)
                    } else {
                        viewModel.navigate(to: .signIn)
                    }
                }
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.accentColor)
                .frame(width: 24)
            Text(text)
                .font(.body)
            Spacer()
        }
    }
}

struct OnboardingSignInView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                Spacer()
                    .frame(height: 60)
                
                // Image
                Image(systemName: "icloud.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.accentColor)
                
                // Title
                Text(Loc.Onboarding.syncYourProgress)
                    .font(.title.bold())
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                
                // Content
                VStack(spacing: 16) {
                    Button(action: {
                        Task {
                            // TODO: Handle Apple Sign In
                            // try? await viewModel.authService.signInWithApple()
                            await MainActor.run {
                                viewModel.completedSignIn = true
                                viewModel.navigate(to: .success)
                            }
                        }
                    }) {
                        HStack {
                            Image(systemName: "apple.logo")
                            Text(Loc.Onboarding.signInWithApple)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.black)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    
                    Button(action: {
                        Task {
                            // TODO: Handle Google Sign In
                            // try? await viewModel.authService.signInWithGoogle()
                            await MainActor.run {
                                viewModel.completedSignIn = true
                                viewModel.navigate(to: .success)
                            }
                        }
                    }) {
                        HStack {
                            Image(systemName: "g.circle.fill")
                            Text(Loc.Onboarding.signInWithGoogle)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 32)
                
                Spacer()
                    .frame(height: 40)
            }
            .frame(maxWidth: .infinity)
        }
        .safeAreaInset(edge: .bottom) {
            Button(Loc.Onboarding.skipForNow) {
                viewModel.navigate(to: .success)
            }
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity)
            .padding()
        }
    }
}

