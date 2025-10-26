//
//  OnboardingSuccessView.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import SwiftUI

extension OnboardingFlow {
    struct SuccessView: View {
        @ObservedObject var viewModel: OnboardingFlow.ViewModel
        @State private var animateContent = false
        @State private var animateBackground = false
        @State private var showPulse = false
        @State private var showCheckmark = false

        var body: some View {
            ScrollView {
                VStack(spacing: 0) {
                    Spacer()
                        .frame(height: 60)

                    // Animated illustration
                    Image(.illustrationAllDone)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 230)
                        .scaleEffect(animateContent ? 1.0 : 0.5)
                        .animation(.spring(response: 1.0, dampingFraction: 0.8), value: animateContent)

                    Spacer()
                        .frame(height: 60)

                    // Title section
                    VStack(spacing: 16) {
                        Text(Loc.Onboarding.youreAllSetName(viewModel.userName))
                            .font(.system(.largeTitle, design: .rounded, weight: .bold))
                            .foregroundStyle(.primary)
                            .opacity(animateContent ? 1 : 0)
                            .offset(y: animateContent ? 0 : 20)

                        Text(Loc.Onboarding.readyToLearnLanguages(Loc.Plurals.Onboarding.languagesCount(viewModel.studyLanguages.count)))
                            .font(.title3)
                            .foregroundStyle(.secondary)
                            .opacity(animateContent ? 1 : 0)
                            .offset(y: animateContent ? 0 : 20)
                    }
                    .multilineTextAlignment(.center)
                    .animation(.easeInOut(duration: 0.8).delay(0.3), value: animateContent)
                    .padding(.horizontal, 16)

                    Spacer()
                        .frame(height: 80)
                }
                .frame(maxWidth: .infinity)
                .padding(vertical: 12, horizontal: 16)
            }
            .withGradientBackground()
            .safeAreaBarIfAvailable {
                ActionButton(Loc.Onboarding.startLearning, style: .borderedProminent) {
                    viewModel.completeOnboarding()
                }
                .padding(vertical: 12, horizontal: 16)
            }
            .overlay(
                Group {
                    if viewModel.isLoading {
                        ProgressView()
                            .scaleEffect(1.5)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color.black.opacity(0.4))
                    }
                }
            )
            .onAppear {
                withAnimation(.easeInOut(duration: 1.0)) {
                    animateContent = true
                    animateBackground = true
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                        showCheckmark = true
                    }
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                        showPulse = true
                    }
                }
            }
        }
    }
}
