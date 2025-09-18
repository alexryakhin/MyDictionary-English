//
//  TargetLanguageOnboardingScreen.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/9/25.
//

import SwiftUI
import Flow

struct TargetLanguageOnboardingScreen: View {
    @ObservedObject var viewModel: LearningOnboardingViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                Spacer(minLength: 20)
                
                // Header Section
                CustomSectionView(header: Loc.Learning.TargetLanguage.chooseTargetLanguage) {
                    VStack(spacing: 12) {
                        Text(Loc.Learning.TargetLanguage.whichLanguageDoYouWantToLearn)
                            .font(.title3)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Text(Loc.Learning.TargetLanguage.thisWillBeTheLanguage)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.vertical, 16)
                }
                
                // Target Language Selection Section
                CustomSectionView(header: "Available Languages") {
                    HFlow(alignment: .top, spacing: 12) {
                        ForEach(InputLanguage.casesWithoutAuto, id: \.self) { language in
                            LanguageCard(
                                language: language,
                                isSelected: viewModel.targetLanguage == language
                            ) {
                                viewModel.targetLanguage = language
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 8)
                }
                
                Spacer(minLength: 20)
            }
            .padding(.horizontal, 16)
        }
        .groupedBackground()
    }
}

struct LanguageCard: View {
    let language: InputLanguage
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        HeaderButton(
            language.displayName,
            color: .accent,
            size: .medium,
            style: isSelected ? .borderedProminent : .bordered,
            action: action
        )
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

#Preview {
    TargetLanguageOnboardingScreen(viewModel: LearningOnboardingViewModel())
}
