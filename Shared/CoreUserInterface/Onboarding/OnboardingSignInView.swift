//
//  OnboardingSignInView.swift
//  My Dictionary
//
//  Created by Alexander Riakhin on 10/17/25.
//

import SwiftUI

/*
extension OnboardingFlow {
struct SignInView: View {
    @ObservedObject var viewModel: OnboardingFlow.ViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Image
                Image(systemName: "icloud.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.accentColor)

                // Title
                Text(Loc.Onboarding.syncYourProgress)
                    .font(.title.bold())
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                // Content
                VStack(spacing: 16) {
                    Button(action: {
                        Task {
                            // TODO: Handle Apple Sign In
                            // try? await viewModel.authService.signInWithApple()
                            await MainActor.run {
                                viewModel.completedSignIn = true
                                viewModel.navigate(to: .success)
                            }
                        }
                    }) {
                        HStack {
                            Image(systemName: "apple.logo")
                            Text(Loc.Onboarding.signInWithApple)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.black)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }

                    Button(action: {
                        Task {
                            // TODO: Handle Google Sign In
                            // try? await viewModel.authService.signInWithGoogle()
                            await MainActor.run {
                                viewModel.completedSignIn = true
                                viewModel.navigate(to: .success)
                            }
                        }
                    }) {
                        HStack {
                            Image(systemName: "g.circle.fill")
                            Text(Loc.Onboarding.signInWithGoogle)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 32)
            }
            .frame(maxWidth: .infinity)
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(Loc.Onboarding.skipForNow) {
                    viewModel.navigate(to: .success)
                }
            }
        }
    }
}
}
*/

