//
//  OnboardingNameView.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import SwiftUI

struct OnboardingNameView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer()
                    .frame(height: 60)
                
                // Image
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 100, height: 100)
                    .foregroundColor(.accentColor)
                
                // Title
                Text(Loc.Onboarding.whatShouldWeCallYou)
                    .font(.title.bold())
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                
                // Content
                TextField(Loc.Onboarding.enterYourName, text: $viewModel.userName)
                    .font(.title2)
                    .multilineTextAlignment(.center)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal, 32)
                    .focused($isTextFieldFocused)
                
                Spacer()
                    .frame(height: 40)
            }
            .frame(maxWidth: .infinity)
        }
        .safeAreaInset(edge: .bottom) {
            ActionButton(Loc.Onboarding.continue) {
                viewModel.navigate(to: .userType)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(Loc.Onboarding.skip) {
                    viewModel.userName = ""
                    viewModel.navigate(to: .userType)
                }
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isTextFieldFocused = true
            }
        }
    }
}

