//
//  MotivationOnboardingScreen.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/9/25.
//

import SwiftUI

struct MotivationOnboardingScreen: View {
    @ObservedObject var viewModel: LearningOnboardingViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                Spacer(minLength: 20)
                
                // Header Section
                CustomSectionView(header: Loc.Learning.Motivation.whatMotivatesYou) {
                    VStack(spacing: 12) {
                        Text(Loc.Learning.Motivation.helpUsKeepYouMotivated)
                            .font(.title3)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Text(Loc.Learning.Motivation.selectMotivation)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.vertical, 16)
                }
                
                // Motivation Selection Section
                CustomSectionView(header: "Motivation Options") {
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12)
                    ], spacing: 12) {
                        ForEach(LearningMotivation.allCases, id: \.self) { motivation in
                            MotivationCard(
                                motivation: motivation,
                                isSelected: viewModel.motivation == motivation
                            ) {
                                viewModel.motivation = motivation
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

struct MotivationCard: View {
    let motivation: LearningMotivation
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: motivation.iconName)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : .accent)
                
                VStack(spacing: 4) {
                    Text(motivation.displayName)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(isSelected ? .white : .primary)
                        .multilineTextAlignment(.center)
                    
                    Text(motivation.description)
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
    MotivationOnboardingScreen(viewModel: LearningOnboardingViewModel())
}
