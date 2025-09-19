//
//  NativeLanguageOnboardingScreen.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/9/25.
//

import SwiftUI
import Flow

struct NativeLanguageOnboardingScreen: View {
    @ObservedObject var viewModel: LearningOnboardingViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {                
                // Header Section
                CustomSectionView(header: Loc.Learning.NativeLanguage.whatIsYourNativeLanguage) {
                    VStack(spacing: 12) {
                        Text(Loc.Learning.NativeLanguage.helpUsExplainThings)
                            .font(.title3)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Text(Loc.Learning.NativeLanguage.selectNativeLanguage)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.vertical, 16)
                }
                
                // Native Language Selection Section
                CustomSectionView(header: "Available Languages") {
                    HFlow(alignment: .top, spacing: 12) {
                        ForEach(InputLanguage.allCasesSorted, id: \.self) { language in
                            LanguageCard(
                                language: language,
                                isSelected: viewModel.nativeLanguage == language
                            ) {
                                viewModel.nativeLanguage = language
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 8)
                }
            }
            .padding(.horizontal, 16)
        }
        .groupedBackground()
    }
}

#Preview {
    NativeLanguageOnboardingScreen(viewModel: LearningOnboardingViewModel())
}
