//
//  OnboardingPaywallView.swift
//  My Dictionary
//
//  Created by Alexander Riakhin on 10/17/25.
//

import SwiftUI

extension OnboardingFlow {
    struct PaywallView: View {
        @ObservedObject var viewModel: OnboardingFlow.ViewModel
        @State private var animateContent = false
        @State private var animateIcon = false
        @State private var showFeatures = false

        var body: some View {
            ScrollView {
                VStack(spacing: 32) {
                    Spacer()
                        .frame(height: 40)

                    // Animated illustration
                    Image(.illustrationPremium)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 200)
                        .scaleEffect(animateContent ? 1.0 : 0.5)
                        .animation(.spring(response: 1.0, dampingFraction: 0.8), value: animateContent)

                    // Title
                    VStack(spacing: 12) {
                        Text(Loc.Onboarding.unlockFullLearningPotential)
                            .font(.system(.title, design: .rounded, weight: .bold))
                            .multilineTextAlignment(.center)

                        Text(Loc.Onboarding.start7DayFreeTrial)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .opacity(animateContent ? 1 : 0)
                    .offset(y: animateContent ? 0 : 20)
                    .animation(.easeInOut(duration: 0.8).delay(0.2), value: animateContent)
                    .padding(.horizontal, 16)

                    // Content - Feature rows
                    VStack(alignment: .leading, spacing: 16) {
                        PremiumFeatureRow(
                            icon: "star.fill",
                            text: Loc.Onboarding.unlimitedWordsAndQuizzes,
                            color: .yellow,
                            delay: 0.0,
                            show: showFeatures
                        )

                        PremiumFeatureRow(
                            icon: "icloud.fill",
                            text: Loc.Onboarding.crossDeviceSync,
                            color: .blue,
                            delay: 0.15,
                            show: showFeatures
                        )

                        PremiumFeatureRow(
                            icon: "sparkles",
                            text: Loc.Onboarding.prioritySupport,
                            color: .purple,
                            delay: 0.3,
                            show: showFeatures
                        )
                    }
                    .padding(.horizontal, 16)
                }
                .frame(maxWidth: .infinity)
            }
            .withGradientBackground()
            .safeAreaBarIfAvailable {
                ActionButton(Loc.Onboarding.startFreeTrial, style: .borderedProminent) {
                    // TODO: Trigger RevenueCat purchase
                    viewModel.navigate(to: .success)
                }
                .padding(vertical: 12, horizontal: 16)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(Loc.Onboarding.skip) {
                        viewModel.skipPaywall()
                        viewModel.navigate(to: .success)
                    }
                }
            }
            .onAppear {
                withAnimation {
                    animateContent = true
                    animateIcon = true
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    showFeatures = true
                }
            }
        }
    }
    
    // MARK: - Premium Feature Row
    
    struct PremiumFeatureRow: View {
        let icon: String
        let text: String
        let color: Color
        let delay: Double
        let show: Bool
        
        var body: some View {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(color.opacity(0.15))
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundStyle(color)
                }
                
                Text(text)
                    .font(.body)
                    .foregroundStyle(.primary)
                
                Spacer()
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.secondarySystemGroupedBackground)
                    .shadow(color: .label.opacity(0.08), radius: 10, x: 0, y: 5)
            )
            .opacity(show ? 1 : 0)
            .offset(x: show ? 0 : -50)
            .animation(.easeInOut(duration: 0.6).delay(delay), value: show)
        }
    }
}
