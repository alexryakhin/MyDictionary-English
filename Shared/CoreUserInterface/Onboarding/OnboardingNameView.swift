//
//  OnboardingNameView.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import SwiftUI

extension OnboardingFlow {
    struct NameView: View {
        @ObservedObject var viewModel: OnboardingFlow.ViewModel
        @FocusState private var isTextFieldFocused: Bool
        @State private var animateContent = false

        var body: some View {
            ScrollView {
                VStack(spacing: 24) {
                    Spacer()
                        .frame(height: 20)

                    // Animated illustration
                    Image(.illustrationName)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 120)
                        .scaleEffect(animateContent ? 1.0 : 0.5)
                        .animation(.spring(response: 1.0, dampingFraction: 0.8), value: animateContent)

                    // Title
                    Text(Loc.Onboarding.whatShouldWeCallYou)
                        .font(.system(.title, design: .rounded, weight: .bold))
                        .multilineTextAlignment(.center)
                        .opacity(animateContent ? 1 : 0)
                        .offset(y: animateContent ? 0 : 20)
                        .animation(.easeInOut(duration: 0.8).delay(0.2), value: animateContent)
                        .padding(.horizontal, 16)

                    // Content
                    TextField(Loc.Onboarding.enterYourName, text: $viewModel.userName)
                        .font(.title2)
                        .multilineTextAlignment(.center)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.secondarySystemGroupedBackground)
                                .shadow(color: .label.opacity(0.1), radius: 8, x: 0, y: 4)
                        )
                        .padding(.horizontal, 32)
                        .focused($isTextFieldFocused)
                        .opacity(animateContent ? 1 : 0)
                        .offset(y: animateContent ? 0 : 20)
                        .animation(.easeInOut(duration: 0.8).delay(0.4), value: animateContent)
                }
                .frame(maxWidth: .infinity)
                .padding(vertical: 12, horizontal: 16)
            }
            .withGradientBackground()
            .safeAreaBarIfAvailable {
                ActionButton(Loc.Onboarding.continue, style: .borderedProminent) {
                    viewModel.navigate(to: .userType)
                }
                .padding(vertical: 12, horizontal: 16)
            }
            .onAppear {
                withAnimation {
                    animateContent = true
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    isTextFieldFocused = true
                }
            }
        }
    }
}
