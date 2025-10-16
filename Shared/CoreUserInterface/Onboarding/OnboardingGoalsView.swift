//
//  OnboardingGoalsView.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import SwiftUI

struct OnboardingGoalsView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    
    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer()
                    .frame(height: 40)
                
                // Image
                Image(systemName: "target")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .foregroundColor(.accentColor)
                
                // Title
                Text(Loc.Onboarding.whyAreYouLearning)
                    .font(.title.bold())
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                
                // Subtitle
                Text(Loc.Onboarding.selectUpToThree)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                // Content
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(LearningGoal.allCases, id: \.self) { goal in
                        SelectableCard(
                            title: goal.displayName,
                            icon: goal.iconName,
                            isSelected: viewModel.selectedGoals.contains(goal)
                        ) {
                            toggleGoal(goal)
                        }
                    }
                }
                .padding(.horizontal, 24)
                
                Spacer()
                    .frame(height: 40)
            }
            .frame(maxWidth: .infinity)
        }
        .safeAreaInset(edge: .bottom) {
            ActionButton(Loc.Onboarding.continue) {
                viewModel.navigate(to: .languages)
            }
            .disabled(!(!viewModel.selectedGoals.isEmpty && viewModel.selectedGoals.count <= 3))
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
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

