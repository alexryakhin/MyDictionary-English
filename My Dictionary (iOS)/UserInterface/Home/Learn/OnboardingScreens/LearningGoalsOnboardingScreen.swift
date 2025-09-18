//
//  LearningGoalsOnboardingScreen.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/9/25.
//

import SwiftUI

struct LearningGoalsOnboardingScreen: View {
    @ObservedObject var viewModel: LearningOnboardingViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                Spacer(minLength: 20)
                
                // Header Section
                CustomSectionView(header: Loc.Learning.LearningGoals.whatAreYourGoals) {
                    VStack(spacing: 12) {
                        Text(Loc.Learning.LearningGoals.helpUsCustomizeYourCourse)
                            .font(.title3)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Text(Loc.Learning.LearningGoals.selectGoals)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.vertical, 16)
                }
                
                // Goals Selection Section
                CustomSectionView(header: "Learning Goals") {
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12)
                    ], spacing: 12) {
                        ForEach(LearningGoal.allCases, id: \.self) { goal in
                            GoalCard(
                                goal: goal,
                                isSelected: viewModel.selectedGoals.contains(goal)
                            ) {
                                viewModel.toggleGoal(goal)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Spacer(minLength: 20)
            }
            .padding(.horizontal, 16)
        }
        .groupedBackground()
    }
}

struct GoalCard: View {
    let goal: LearningGoal
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: goal.iconName)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : .accent)
                
                VStack(spacing: 4) {
                    Text(goal.displayName)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(isSelected ? .white : .primary)
                        .multilineTextAlignment(.center)
                    
                    Text(goal.description)
                        .font(.caption)
                        .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                }
            }
            .frame(height: 140)
            .frame(maxWidth: .infinity)
            .padding(12)
            .foregroundStyle(foregroundStyle)
            .background(backgroundStyle)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isSelected)
        }
        .buttonStyle(.plain)
    }
    
    var foregroundStyle: Color {
        isSelected ? .white : .primary
    }

    var backgroundStyle: Color {
        isSelected ? .accent : .tertiarySystemGroupedBackground
    }
}

#Preview {
    LearningGoalsOnboardingScreen(viewModel: LearningOnboardingViewModel())
}
