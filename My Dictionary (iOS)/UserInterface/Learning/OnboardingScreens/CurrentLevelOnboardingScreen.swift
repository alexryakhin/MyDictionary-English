//
//  CurrentLevelOnboardingScreen.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/9/25.
//

import SwiftUI

struct CurrentLevelOnboardingScreen: View {
    @ObservedObject var viewModel: LearningOnboardingViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                Spacer(minLength: 20)
                
                // Header Section
                CustomSectionView(header: Loc.Learning.CurrentLevel.whatIsYourCurrentLevel) {
                    VStack(spacing: 12) {
                        Text(Loc.Learning.CurrentLevel.helpUsUnderstand)
                            .font(.title3)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Text(Loc.Learning.CurrentLevel.selectYourLevel)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.vertical, 16)
                }
                
                // Level Selection Section
                CustomSectionView(header: "Language Levels") {
                    VStack(spacing: 12) {
                        ForEach(LanguageLevel.allCases, id: \.self) { level in
                            LevelCard(
                                level: level,
                                isSelected: viewModel.currentLevel == level
                            ) {
                                viewModel.currentLevel = level
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

struct LevelCard: View {
    let level: LanguageLevel
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon
                Image(systemName: level.iconName)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : .accent)
                    .frame(width: 30)
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(level.displayName)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(isSelected ? .white : .primary)
                    
                    Text(level.description)
                        .font(.subheadline)
                        .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                // Selection indicator
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.white)
                    .hidden(!isSelected)
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
    CurrentLevelOnboardingScreen(viewModel: LearningOnboardingViewModel())
}
