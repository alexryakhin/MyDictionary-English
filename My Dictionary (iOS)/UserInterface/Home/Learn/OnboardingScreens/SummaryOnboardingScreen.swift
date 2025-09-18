//
//  SummaryOnboardingScreen.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/9/25.
//

import SwiftUI

struct SummaryOnboardingScreen: View {
    @ObservedObject var viewModel: LearningOnboardingViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                Spacer(minLength: 20)
                
                // Header Section
                CustomSectionView(header: Loc.Learning.Summary.yourLearningProfile) {
                    VStack(spacing: 12) {
                        Text(Loc.Learning.Summary.hereIsWhatWeLearned)
                            .font(.title3)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.vertical, 16)
                }
                
                // Learning Goal Section
                CustomSectionView(header: "Learning Goal") {
                    VStack(alignment: .leading, spacing: 8) {
                        ProfileRow(
                            icon: "globe",
                            label: "Target Language",
                            value: viewModel.targetLanguage.displayName
                        )
                        ProfileRow(
                            icon: "chart.bar.fill",
                            label: "Current Level",
                            value: viewModel.currentLevel.displayName
                        )
                        ProfileRow(
                            icon: "person.circle.fill",
                            label: "Native Language",
                            value: viewModel.nativeLanguage.displayName
                        )
                    }
                    .padding(.vertical, 8)
                }
                
                // Goals & Motivation Section
                CustomSectionView(header: "Goals & Motivation") {
                    VStack(alignment: .leading, spacing: 8) {
                        ProfileRow(
                            icon: "target",
                            label: "Goals",
                            value: viewModel.selectedGoals.map { $0.displayName }.joined(separator: ", ")
                        )
                        ProfileRow(
                            icon: "heart.fill",
                            label: "Motivation",
                            value: viewModel.motivation.displayName
                        )
                    }
                    .padding(.vertical, 8)
                }
                
                // Learning Preferences Section
                CustomSectionView(header: "Learning Preferences") {
                    VStack(alignment: .leading, spacing: 8) {
                        ProfileRow(
                            icon: "brain.head.profile",
                            label: "Learning Style",
                            value: viewModel.learningStyle.displayName
                        )
                        ProfileRow(
                            icon: "clock.fill",
                            label: "Time Commitment",
                            value: "\(viewModel.timeCommitment.displayName) (\(viewModel.timeCommitment.minutesPerDay) min/day)"
                        )
                    }
                    .padding(.vertical, 8)
                }
                
                // Interests Section
                if !viewModel.selectedInterests.isEmpty {
                    CustomSectionView(header: "Interests (\(viewModel.selectedInterests.count))") {
                        VStack(alignment: .leading, spacing: 8) {
                            ProfileRow(
                                icon: "star.fill",
                                label: "Selected Interests",
                                value: viewModel.selectedInterests.map { $0.title }.joined(separator: ", ")
                            )
                        }
                        .padding(.vertical, 8)
                    }
                }
                
                // Ready to Start Section
                CustomSectionView(header: Loc.Learning.Summary.readyToStart) {
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.green)
                        
                        Text(Loc.Learning.Summary.letSBeginYourJourney)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.vertical, 20)
                }
                
                Spacer(minLength: 20)
            }
            .padding(.horizontal, 16)
        }
        .groupedBackground()
    }
}

struct ProfileRow: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundColor(.accent)
                .frame(width: 20)
            
            Text(label)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.trailing)
        }
    }
}

#Preview {
    SummaryOnboardingScreen(viewModel: LearningOnboardingViewModel())
}
