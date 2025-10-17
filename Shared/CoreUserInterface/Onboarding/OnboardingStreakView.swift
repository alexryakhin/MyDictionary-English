//
//  OnboardingStreakView.swift
//  My Dictionary
//
//  Created by Alexander Riakhin on 10/17/25.
//

import SwiftUI

extension OnboardingFlow {
    struct StreakView: View {
        @ObservedObject var viewModel: OnboardingFlow.ViewModel
        @State private var animateContent = false
        @State private var animateFlame = false
        @State private var showBenefits = false

        var body: some View {
            ZStack {
                // Animated background
                backgroundGradient
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 32) {
                        Spacer()
                            .frame(height: 40)

                        // Animated flame icon
                        ZStack {
                            Circle()
                                .fill(Color.orange.opacity(0.1))
                                .frame(width: 140, height: 140)
                                .scaleEffect(animateFlame ? 1.1 : 1.0)

                            Image(systemName: "flame.fill")
                                .font(.system(size: 70))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.orange, .red],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .scaleEffect(animateContent ? 1.0 : 0.5)
                                .rotationEffect(.degrees(animateFlame ? -10 : 10))
                        }
                        .animation(.spring(response: 1.0, dampingFraction: 0.8), value: animateContent)
                        .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: animateFlame)

                        // Title
                        VStack(spacing: 16) {
                            Text(Loc.Onboarding.buildYourLearningStreak)
                                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                                .foregroundStyle(.primary)
                                .multilineTextAlignment(.center)
                                .opacity(animateContent ? 1 : 0)
                                .offset(y: animateContent ? 0 : 20)

                            Text(Loc.Onboarding.streakIntroMessage)
                                .font(.body)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .opacity(animateContent ? 1 : 0)
                                .offset(y: animateContent ? 0 : 20)
                        }
                        .animation(.easeInOut(duration: 0.8).delay(0.3), value: animateContent)
                        .padding(.horizontal, 32)

                        // Streak benefits
                        VStack(spacing: 12) {
                            StreakBenefitRow(
                                icon: "calendar",
                                title: "Daily Consistency",
                                description: "Build a habit that sticks",
                                delay: 0.0,
                                show: showBenefits
                            )

                            StreakBenefitRow(
                                icon: "chart.line.uptrend.xyaxis",
                                title: "Track Progress",
                                description: "Watch your vocabulary grow",
                                delay: 0.15,
                                show: showBenefits
                            )

                            StreakBenefitRow(
                                icon: "star.fill",
                                title: "Stay Motivated",
                                description: "Keep your streak alive",
                                delay: 0.3,
                                show: showBenefits
                            )
                        }
                        .padding(.horizontal, 24)

                        Spacer()
                            .frame(height: 40)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .safeAreaBarIfAvailable {
                ActionButton(Loc.Onboarding.soundsGreat, style: .borderedProminent) {
                    viewModel.navigate(to: .notifications)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 1.0)) {
                    animateContent = true
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation {
                        animateFlame = true
                        showBenefits = true
                    }
                }
            }
        }

        private var backgroundGradient: some View {
            LinearGradient(
                colors: [
                    Color.orange.opacity(0.08),
                    Color.accentColor.opacity(0.05),
                    Color.systemBackground
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    // MARK: - Streak Benefit Row

    struct StreakBenefitRow: View {
        let icon: String
        let title: String
        let description: String
        let delay: Double
        let show: Bool

        var body: some View {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.accentColor.opacity(0.1))
                        .frame(width: 56, height: 56)

                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundStyle(Color.accentColor)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Text(description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.systemBackground)
                    .shadow(color: .label.opacity(0.05), radius: 8, x: 0, y: 4)
            )
            .opacity(show ? 1 : 0)
            .offset(x: show ? 0 : -50)
            .animation(.easeInOut(duration: 0.6).delay(delay), value: show)
        }
    }
}
