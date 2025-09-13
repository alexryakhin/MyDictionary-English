//
//  LearningStyleOnboardingScreen.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/9/25.
//

import SwiftUI

struct LearningStyleOnboardingScreen: View {
    @ObservedObject var viewModel: LearningOnboardingViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                Spacer(minLength: 20)
                
                // Header Section
                CustomSectionView(header: Loc.Learning.LearningStyle.whatIsYourLearningStyle) {
                    VStack(spacing: 12) {
                        Text(Loc.Learning.LearningStyle.helpUsAdaptToYou)
                            .font(.title3)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Text(Loc.Learning.LearningStyle.selectLearningStyle)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.vertical, 16)
                }
                
                // Learning Style Selection Section
                CustomSectionView(header: "Learning Styles") {
                    VStack(spacing: 12) {
                        ForEach(LearningStyle.allCases, id: \.self) { style in
                            LearningStyleCard(
                                style: style,
                                isSelected: viewModel.learningStyle == style
                            ) {
                                viewModel.learningStyle = style
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

struct LearningStyleCard: View {
    let style: LearningStyle
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: style.iconName)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : .accent)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(style.displayName)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(isSelected ? .white : .primary)
                    
                    Text(style.description)
                        .font(.subheadline)
                        .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
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
    LearningStyleOnboardingScreen(viewModel: LearningOnboardingViewModel())
}
