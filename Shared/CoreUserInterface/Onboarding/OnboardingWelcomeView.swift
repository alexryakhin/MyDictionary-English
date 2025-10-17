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
        @State private var animateContent = false
        @State private var animateBackground = false
        @State private var showPulse = false

        var body: some View {
            ZStack {
                // Animated background
                backgroundGradient
                    .ignoresSafeArea()
                    .scaleEffect(animateBackground ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 8).repeatForever(autoreverses: true), value: animateBackground)

                ScrollView {
                    VStack(spacing: 0) {
                        Spacer()
                            .frame(height: 60)

                        // App icon with animation
                        ZStack {
                            Circle()
                                .fill(Color.accentColor.opacity(0.1))
                                .frame(width: 120, height: 120)
                                .scaleEffect(showPulse ? 1.1 : 1.0)

                            Image(.iconRounded)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 100)
                                .scaleEffect(animateContent ? 1.0 : 0.5)
                                .rotationEffect(.degrees(animateContent ? 0 : -180))
                        }
                        .animation(.spring(response: 1.0, dampingFraction: 0.8), value: animateContent)
                        .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: showPulse)

                        Spacer()
                            .frame(height: 60)

                        // Title section
                        VStack(spacing: 16) {
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
                        .multilineTextAlignment(.center)
                        .animation(.easeInOut(duration: 0.8).delay(0.3), value: animateContent)
                        .padding(.horizontal, 32)

                        Spacer()
                            .frame(height: 80)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .safeAreaBarIfAvailable {
                ActionButton(Loc.Onboarding.getStarted, style: .borderedProminent) {
                    viewModel.navigate(to: .name)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
            }
            .onAppear {
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

        private var backgroundGradient: some View {
            LinearGradient(
                colors: [
                    Color.accentColor.opacity(0.1),
                    Color.accentColor.opacity(0.05),
                    Color.systemBackground
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}
