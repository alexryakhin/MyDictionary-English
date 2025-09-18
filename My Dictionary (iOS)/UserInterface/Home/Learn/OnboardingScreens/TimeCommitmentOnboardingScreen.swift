//
//  TimeCommitmentOnboardingScreen.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/9/25.
//

import SwiftUI

struct TimeCommitmentOnboardingScreen: View {
    @ObservedObject var viewModel: LearningOnboardingViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                Spacer(minLength: 20)
                
                // Header Section
                CustomSectionView(header: Loc.Learning.TimeCommitment.howMuchTime) {
                    VStack(spacing: 12) {
                        Text(Loc.Learning.TimeCommitment.helpUsPlanYourSchedule)
                            .font(.title3)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Text(Loc.Learning.TimeCommitment.selectTimeCommitment)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.vertical, 16)
                }
                
                // Time Commitment Selection Section
                CustomSectionView(header: "Time Commitment Options") {
                    VStack(spacing: 12) {
                        ForEach(TimeCommitment.allCases, id: \.self) { commitment in
                            TimeCommitmentCard(
                                commitment: commitment,
                                isSelected: viewModel.timeCommitment == commitment
                            ) {
                                viewModel.timeCommitment = commitment
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

struct TimeCommitmentCard: View {
    let commitment: TimeCommitment
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon
                Image(systemName: commitment.iconName)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : .accent)
                    .frame(width: 30)
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(commitment.displayName)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(isSelected ? .white : .primary)
                    
                    Text(commitment.description)
                        .font(.subheadline)
                        .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                // Time indicator
                Text("\(commitment.minutesPerDay) min/day")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .accent)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(isSelected ? Color.white.opacity(0.2) : Color.accent.opacity(0.1))
                    )
            }
            .padding(16)
            .foregroundStyle(foregroundStyle)
            .background(backgroundStyle)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
    
    var foregroundStyle: Color {
        isSelected ? .white : .primary
    }

    var backgroundStyle: Color {
        isSelected ? .accent : .tertiarySystemGroupedBackground
    }
}

#Preview {
    TimeCommitmentOnboardingScreen(viewModel: LearningOnboardingViewModel())
}
