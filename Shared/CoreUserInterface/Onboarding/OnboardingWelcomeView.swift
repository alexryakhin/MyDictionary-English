//
//  OnboardingWelcomeView.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import SwiftUI

extension OnboardingFlow {
    struct WelcomeView: View {
        @ObservedObject var viewModel: OnboardingFlow.ViewModel
        @StateObject private var onboardingService = OnboardingService.shared
        @State private var animateContent = false
        @State private var animateBackground = false
        @State private var showPulse = false

        var body: some View {
            VStack(spacing: 24) {
                Spacer()

                Image(.illustrationReadingTime)
                    .resizable()
                    .scaledToFit()
                    .scaleEffect(animateContent ? 1.0 : 0.5)

                Spacer()

                // Title section
                VStack(alignment: .leading, spacing: 8) {
                    Text(Loc.Onboarding.welcomeTo)
                        .font(.title2)
                        .foregroundStyle(.secondary)
                        .opacity(animateContent ? 1 : 0)
                        .offset(y: animateContent ? 0 : 20)

                    Text(Loc.Onboarding.myDictionary)
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                        .opacity(animateContent ? 1 : 0)
                        .offset(y: animateContent ? 0 : 20)

                    Text(Loc.Onboarding.personalVocabularyCompanion)
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .opacity(animateContent ? 1 : 0)
                        .offset(y: animateContent ? 0 : 20)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .multilineTextAlignment(.leading)

                VStack(spacing: 8) {
                    cloudProfileStatusView
                        .multilineTextAlignment(.center)
                        .animation(.easeInOut(duration: 0.8).delay(0.3), value: animateContent)

                    ActionButton(
                        buttonText,
                        style: .borderedProminent,
                        action: handleButtonAction
                    )
                    .disabled(onboardingService.isLoadingFromCloud)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(vertical: 12, horizontal: 16)
            .withGradientBackground()
            .onAppear {
                logInfo("[OnboardingWelcomeView] Appeared – isLoadingFromCloud=\(onboardingService.isLoadingFromCloud) hasFoundCloudProfile=\(onboardingService.hasFoundCloudProfile)")
                withAnimation(.easeInOut(duration: 1.0)) {
                    animateContent = true
                    animateBackground = true
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                        showPulse = true
                    }
                }
            }
        }
        
        // MARK: - Cloud Profile Status View
        
        @ViewBuilder
        private var cloudProfileStatusView: some View {
            if onboardingService.isLoadingFromCloud {
                // Loading state
                HStack(spacing: 8) {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.accent)
                    
                    Text(onboardingService.cloudLoadingMessage)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .opacity(animateContent ? 1 : 0)
                .offset(y: animateContent ? 0 : 20)
                .animation(.easeInOut(duration: 0.8).delay(0.5), value: animateContent)
            } else if onboardingService.hasFoundCloudProfile {
                // Profile found state
                VStack(alignment: .leading, spacing: 8) {
                    Label(Loc.Onboarding.profileFound, systemImage: "checkmark.circle.fill")
                        .font(.headline)
                    Text(Loc.Onboarding.profileFoundMessage)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .multilineTextAlignment(.leading)
                .opacity(animateContent ? 1 : 0)
                .offset(y: animateContent ? 0 : 20)
                .animation(.easeInOut(duration: 0.8).delay(0.5), value: animateContent)
            }
        }
        
        // MARK: - Button Logic
        
        private var buttonText: String {
            if onboardingService.isLoadingFromCloud {
                return onboardingService.cloudLoadingMessage
            } else if onboardingService.hasFoundCloudProfile {
                return Loc.Onboarding.getStarted
            } else {
                return Loc.Onboarding.getStarted
            }
        }
        
        private func handleButtonAction() {
            logInfo("[OnboardingWelcomeView] Primary button tapped – hasFoundCloudProfile=\(onboardingService.hasFoundCloudProfile)")
            if onboardingService.hasFoundCloudProfile {
                // User wants to proceed with existing cloud profile
                onboardingService.proceedWithCloudProfile()
                logSuccess("[OnboardingWelcomeView] Proceeded with existing cloud profile")
            } else {
                // Normal onboarding flow
                viewModel.navigate(to: .name)
            }
        }
    }
}

#Preview {
    OnboardingFlow.WelcomeView(viewModel: .init(isNewUser: true))
}
