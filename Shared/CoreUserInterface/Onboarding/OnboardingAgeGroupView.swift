//
//  OnboardingAgeGroupView.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import SwiftUI

struct OnboardingAgeGroupView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer()
                    .frame(height: 40)
                
                // Image
                Image(systemName: "calendar.circle.fill")
                    .resizable()
                    .frame(width: 80, height: 80)
                    .foregroundColor(.accentColor)
                
                // Title
                Text(Loc.Onboarding.whatsYourAgeGroup)
                    .font(.title.bold())
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                
                // Content
                VStack(spacing: 12) {
                    ForEach(AgeGroup.allCases, id: \.self) { ageGroup in
                        Button(action: {
                            viewModel.selectedAgeGroup = ageGroup
                        }) {
                            HStack {
                                Text(ageGroup.emoji)
                                    .font(.title)
                                
                                Text(ageGroup.displayName)
                                    .font(.headline)
                                
                                Spacer()
                                
                                if viewModel.selectedAgeGroup == ageGroup {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.accentColor)
                                }
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(viewModel.selectedAgeGroup == ageGroup
                                          ? Color.accentColor.opacity(0.1)
                                          : Color.gray.opacity(0.1))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(viewModel.selectedAgeGroup == ageGroup
                                            ? Color.accentColor
                                            : Color.clear, lineWidth: 2)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 24)
                
                Spacer()
                    .frame(height: 40)
            }
            .frame(maxWidth: .infinity)
        }
        .safeAreaInset(edge: .bottom) {
            ActionButton(Loc.Onboarding.continue) {
                viewModel.navigate(to: .goals)
            }
            .disabled(viewModel.selectedAgeGroup == nil)
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
        }
    }
}

