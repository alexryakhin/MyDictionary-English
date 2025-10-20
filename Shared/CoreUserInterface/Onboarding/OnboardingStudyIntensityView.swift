//
//  OnboardingStudyIntensityView.swift
//  My Dictionary
//
//  Created by Alexander Riakhin on 10/17/25.
//

import SwiftUI

extension OnboardingFlow {
    struct StudyIntensityView: View {
        @ObservedObject var viewModel: OnboardingFlow.ViewModel
        @State private var animateContent = false

        private let weeklyGoals = [10, 25, 50, 100]

        var body: some View {
            ScrollView {
                VStack(spacing: 32) {
                    Spacer()
                        .frame(height: 40)

                    // Animated illustration
                    Image(.illustrationTarget)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 200)
                        .scaleEffect(animateContent ? 1.0 : 0.5)
                        .animation(.spring(response: 1.0, dampingFraction: 0.8), value: animateContent)

                    Text(Loc.Onboarding.howManyWordsPerWeek)
                        .font(.system(.title, design: .rounded, weight: .bold))
                        .multilineTextAlignment(.center)
                        .opacity(animateContent ? 1 : 0)
                        .offset(y: animateContent ? 0 : 20)
                        .animation(.easeInOut(duration: 0.8).delay(0.2), value: animateContent)
                        .padding(.horizontal, 16)

                    Picker("Weekly Goal", selection: $viewModel.weeklyWordGoal) {
                        ForEach(weeklyGoals, id: \.self) { goal in
                            Text(Loc.Onboarding.wordsPerWeek(goal))
                                .font(.caption)
                                .tag(goal)
                        }
                    }
                    .padding(.vertical, -16)
                    .opacity(animateContent ? 1 : 0)
                    .scaleEffect(animateContent ? 1.0 : 0.95)
                    .animation(.easeInOut(duration: 0.8).delay(0.4), value: animateContent)
                }
                .padding(vertical: 12, horizontal: 16)
            }
            .withGradientBackground()
            .safeAreaBarIfAvailable {
                VStack(spacing: 12) {
                    Text(Loc.Onboarding.estimatedDailyTime(viewModel.weeklyWordGoal / 7 * 2))
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    ActionButton(Loc.Onboarding.continue, style: .borderedProminent) {
                        viewModel.navigate(to: .studyTime)
                    }
                }
                .padding(vertical: 12, horizontal: 16)
            }
            .onAppear {
                withAnimation {
                    animateContent = true
                }
            }
        }
    }
}
