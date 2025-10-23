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
                    .navigationDestination(for: OnboardingFlow.Step.self) { step in
                        stepView(for: step)
                            .navigationBarBackButtonHidden(true)
                            .safeAreaBarIfAvailable(edge: .top) {
                                HStack {
                                    HeaderButton(
                                        Loc.Onboarding.back,
                                        icon: "chevron.left",
                                        action: viewModel.goBack
                                    )
                                    .background(in: .capsule)
                                    Spacer()
                                    if step == .paywall {
                                        HeaderButton(
                                            Loc.Onboarding.skip,
                                            action: viewModel.skipPaywall
                                        )
                                        .background(in: .capsule)
                                    }
                                }
                                .padding(vertical: 12, horizontal: 16)
                            }
                    }
            }
            .withGradientBackground()
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
