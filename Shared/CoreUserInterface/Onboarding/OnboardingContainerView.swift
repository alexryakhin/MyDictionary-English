//
//  OnboardingContainerView.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import SwiftUI
import Flow

enum OnboardingFlow {
    struct ContainerView: View {
        @StateObject private var viewModel: OnboardingFlow.ViewModel
        @Environment(\.dismiss) var dismiss

        init(isNewUser: Bool? = nil) {
            let isNew = isNewUser ?? !UDService.hasCompletedOnboarding
            _viewModel = StateObject(wrappedValue: OnboardingFlow.ViewModel(isNewUser: isNew))
        }

        var body: some View {
            NavigationStack(path: $viewModel.navigationPath) {
                // Initial screen (Welcome)
                OnboardingFlow.WelcomeView(viewModel: viewModel)
                    .navigationBarTitleDisplayMode(.inline)
                    .navigationDestination(for: OnboardingFlow.Step.self) { step in
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
        private func stepView(for step: OnboardingFlow.Step) -> some View {
            switch step {
            case .welcome:
                OnboardingFlow.WelcomeView(viewModel: viewModel)
            case .name:
                OnboardingFlow.NameView(viewModel: viewModel)
            case .userType:
                OnboardingFlow.UserTypeView(viewModel: viewModel)
            case .ageGroup:
                OnboardingFlow.AgeGroupView(viewModel: viewModel)
            case .goals:
                OnboardingFlow.GoalsView(viewModel: viewModel)
            case .languages:
                OnboardingFlow.LanguagesView(viewModel: viewModel)
            case .nativeLanguage:
                OnboardingFlow.NativeLanguageView(viewModel: viewModel)
            case .interests:
                OnboardingFlow.InterestsView(viewModel: viewModel)
            case .studyIntensity:
                OnboardingFlow.StudyIntensityView(viewModel: viewModel)
            case .studyTime:
                OnboardingFlow.StudyTimeView(viewModel: viewModel)
            case .streak:
                OnboardingFlow.StreakView(viewModel: viewModel)
            case .notifications:
                OnboardingFlow.NotificationsView(viewModel: viewModel)
            case .paywall:
                OnboardingFlow.PaywallView(viewModel: viewModel)
            case .success:
                OnboardingFlow.SuccessView(viewModel: viewModel)
            }
        }
    }
}
