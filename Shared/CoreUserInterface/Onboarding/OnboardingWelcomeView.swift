//
//  OnboardingWelcomeView.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import SwiftUI

struct OnboardingWelcomeView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer()
                    .frame(height: 60)
                
                // Image
                Image(systemName: "book.circle.fill")
                    .resizable()
                    .frame(width: 120, height: 120)
                    .foregroundColor(.accentColor)
                
                // Title
                Text(Loc.Onboarding.welcomeTo)
                    .font(.title2)
                    .foregroundColor(.secondary)
                
                Text(Loc.Onboarding.myDictionary)
                    .font(.system(size: 42, weight: .bold))
                    .multilineTextAlignment(.center)
                
                // Subtitle
                Text(Loc.Onboarding.personalVocabularyCompanion)
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                
                Spacer()
                    .frame(height: 40)
            }
            .frame(maxWidth: .infinity)
        }
        .safeAreaInset(edge: .bottom) {
            ActionButton(Loc.Onboarding.getStarted) {
                viewModel.navigate(to: .name)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
        }
    }
}

