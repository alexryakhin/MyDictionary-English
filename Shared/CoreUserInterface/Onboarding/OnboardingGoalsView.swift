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
            ZStack {
                backgroundGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 32) {
                        Spacer()
                            .frame(height: 40)
                        
                        // Animated icon
                        ZStack {
                            Circle()
                                .fill(Color.orange.opacity(0.1))
                                .frame(width: 120, height: 120)
                            
                            Image(systemName: "target")
                                .font(.system(size: 50))
                                .foregroundStyle(Color.orange)
                                .scaleEffect(animateContent ? 1.0 : 0.5)
                        }
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
                        .padding(.horizontal, 32)
                        
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
                        .padding(.horizontal, 24)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .safeAreaBarIfAvailable {
                ActionButton(Loc.Onboarding.continue, style: .borderedProminent) {
                    viewModel.navigate(to: .languages)
                }
                .disabled(!(!viewModel.selectedGoals.isEmpty && viewModel.selectedGoals.count <= 3))
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
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

        private func toggleGoal(_ goal: LearningGoal) {
            if viewModel.selectedGoals.contains(goal) {
                viewModel.selectedGoals.remove(goal)
            } else if viewModel.selectedGoals.count < 3 {
                viewModel.selectedGoals.insert(goal)
            }
        }
    }
}
