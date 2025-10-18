//
//  OnboardingGoalsView.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import SwiftUI

extension OnboardingFlow {
    struct GoalsView: View {
        @ObservedObject var viewModel: OnboardingFlow.ViewModel
        @State private var animateContent = false
        @State private var showCards = false

        private let columns = [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ]

        var body: some View {
            ScrollView {
                VStack(spacing: 32) {
                    Spacer()
                        .frame(height: 40)

                    // Animated illustration
                    Image(.illustrationGoals)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 200)
                        .scaleEffect(animateContent ? 1.0 : 0.5)
                        .animation(.spring(response: 1.0, dampingFraction: 0.8), value: animateContent)

                    // Title
                    VStack(spacing: 12) {
                        Text(Loc.Onboarding.whyAreYouLearning)
                            .font(.system(.title, design: .rounded, weight: .bold))
                            .multilineTextAlignment(.center)

                        Text(Loc.Onboarding.selectUpToThree)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .opacity(animateContent ? 1 : 0)
                    .offset(y: animateContent ? 0 : 20)
                    .animation(.easeInOut(duration: 0.8).delay(0.2), value: animateContent)
                    .padding(.horizontal, 16)

                    // Content
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(Array(LearningGoal.allCases.enumerated()), id: \.element) { index, goal in
                            SelectableCard(
                                title: goal.displayName,
                                icon: goal.iconName,
                                isSelected: viewModel.selectedGoals.contains(goal)
                            ) {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                    toggleGoal(goal)
                                }
                            }
                            .opacity(showCards ? 1 : 0)
                            .offset(y: showCards ? 0 : 30)
                            .animation(.easeInOut(duration: 0.6).delay(0.4 + Double(index) * 0.08), value: showCards)
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .frame(maxWidth: .infinity)
                .padding(vertical: 12, horizontal: 16)
            }
            .withGradientBackground()
            .safeAreaBarIfAvailable {
                ActionButton(Loc.Onboarding.continue, style: .borderedProminent) {
                    viewModel.navigate(to: .languages)
                }
                .disabled(!(!viewModel.selectedGoals.isEmpty && viewModel.selectedGoals.count <= 3))
                .padding(vertical: 12, horizontal: 16)
            }
            .onAppear {
                withAnimation {
                    animateContent = true
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    showCards = true
                }
            }
        }

        private func toggleGoal(_ goal: LearningGoal) {
            if viewModel.selectedGoals.contains(goal) {
                viewModel.selectedGoals.remove(goal)
            } else if viewModel.selectedGoals.count < 3 {
                viewModel.selectedGoals.insert(goal)
            }
        }
    }
}
