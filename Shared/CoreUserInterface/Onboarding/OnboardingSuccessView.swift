//
//  OnboardingSuccessView.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import SwiftUI

struct OnboardingSuccessView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                Spacer()
                    .frame(height: 80)
                
                // Image
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 100))
                    .foregroundColor(.green)
                
                // Title
                Text(Loc.Onboarding.youreAllSetName(viewModel.userName.isEmpty ? "Friend" : viewModel.userName))
                    .font(.title.bold())
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                
                // Subtitle
                Text(Loc.Onboarding.readyToLearnLanguages(viewModel.studyLanguages.count))
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
            ActionButton(Loc.Onboarding.startLearning) {
                viewModel.completeOnboarding()
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
        }
        .overlay(
            Group {
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.4))
                }
            }
        )
    }
}

