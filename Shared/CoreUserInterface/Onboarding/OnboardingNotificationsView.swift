//
//  OnboardingNotificationsView.swift
//  My Dictionary
//
//  Created by Alexander Riakhin on 10/17/25.
//

import SwiftUI

extension OnboardingFlow {
    struct NotificationsView: View {
        @ObservedObject var viewModel: OnboardingFlow.ViewModel
        @State private var animateContent = false
        @State private var animateBell = false
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

                        // Animated bell icon
                        ZStack {
                            Circle()
                                .fill(Color.blue.opacity(0.1))
                                .frame(width: 140, height: 140)
                                .scaleEffect(animateBell ? 1.1 : 1.0)

                            Image(systemName: "bell.badge.fill")
                                .font(.system(size: 60))
                                .foregroundStyle(Color.blue)
                                .scaleEffect(animateContent ? 1.0 : 0.5)
                                .rotationEffect(.degrees(animateBell ? -15 : 15))
                        }
                        .animation(.spring(response: 1.0, dampingFraction: 0.8), value: animateContent)
                        .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: animateBell)

                        // Title
                        VStack(spacing: 16) {
                            Text(Loc.Onboarding.stayOnTrackWithReminders)
                                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                                .foregroundStyle(.primary)
                                .multilineTextAlignment(.center)
                                .opacity(animateContent ? 1 : 0)
                                .offset(y: animateContent ? 0 : 20)

                            Text("We'll send you gentle reminders to help you maintain your learning streak")
                                .font(.body)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .opacity(animateContent ? 1 : 0)
                                .offset(y: animateContent ? 0 : 20)
                        }
                        .animation(.easeInOut(duration: 0.8).delay(0.3), value: animateContent)
                        .padding(.horizontal, 32)

                        // Notification benefits
                        VStack(spacing: 12) {
                            NotificationBenefitRow(
                                icon: "alarm",
                                title: "Daily Reminders",
                                description: "Never miss your study time",
                                delay: 0.0,
                                show: showBenefits
                            )

                            NotificationBenefitRow(
                                icon: "sparkles",
                                title: "Smart Timing",
                                description: "Personalized to your schedule",
                                delay: 0.15,
                                show: showBenefits
                            )

                            NotificationBenefitRow(
                                icon: "hand.raised.fill",
                                title: "No Spam",
                                description: "Only helpful reminders",
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
                VStack(spacing: 12) {
                    AsyncActionButton(Loc.Onboarding.enableNotifications, style: .borderedProminent) {
                        await NotificationService.shared.requestPermission()
                        await MainActor.run {
                            viewModel.enabledNotifications = true
                            if viewModel.subscriptionService.isProUser {
                                viewModel.navigate(to: .success)
                            } else {
                                viewModel.navigate(to: .paywall)
                            }
                        }
                    }

                    Button(Loc.Onboarding.maybeLater) {
                        viewModel.enabledNotifications = false
                        if viewModel.subscriptionService.isProUser {
                            viewModel.navigate(to: .success)
                        } else {
                            viewModel.navigate(to: .paywall)
                        }
                    }
                    .foregroundColor(.secondary)
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
                        animateBell = true
                        showBenefits = true
                    }
                }
            }
        }

        private var backgroundGradient: some View {
            LinearGradient(
                colors: [
                    Color.blue.opacity(0.08),
                    Color.accentColor.opacity(0.05),
                    Color.systemBackground
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    // MARK: - Notification Benefit Row

    struct NotificationBenefitRow: View {
        let icon: String
        let title: String
        let description: String
        let delay: Double
        let show: Bool

        var body: some View {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.blue.opacity(0.1))
                        .frame(width: 56, height: 56)

                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundStyle(Color.blue)
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
