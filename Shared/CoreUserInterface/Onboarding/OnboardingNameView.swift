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
        @State private var animateIcon = false
        
        var body: some View {
            ZStack {
                backgroundGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 32) {
                        Spacer()
                            .frame(height: 40)
                        
                        // Animated icon
                        ZStack {
                            Circle()
                                .fill(Color.purple.opacity(0.1))
                                .frame(width: 120, height: 120)
                                .scaleEffect(animateIcon ? 1.1 : 1.0)
                            
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 60))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.purple, .pink],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .scaleEffect(animateContent ? 1.0 : 0.5)
                        }
                        .animation(.spring(response: 1.0, dampingFraction: 0.8), value: animateContent)
                        .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: animateIcon)
                        
                        // Title
                        Text(Loc.Onboarding.whatShouldWeCallYou)
                            .font(.system(.title, design: .rounded, weight: .bold))
                            .multilineTextAlignment(.center)
                            .opacity(animateContent ? 1 : 0)
                            .offset(y: animateContent ? 0 : 20)
                            .animation(.easeInOut(duration: 0.8).delay(0.2), value: animateContent)
                            .padding(.horizontal, 32)
                        
                        // Content
                        TextField(Loc.Onboarding.enterYourName, text: $viewModel.userName)
                            .font(.title2)
                            .multilineTextAlignment(.center)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.systemBackground)
                                    .shadow(color: .label.opacity(0.1), radius: 8, x: 0, y: 4)
                            )
                            .padding(.horizontal, 32)
                            .focused($isTextFieldFocused)
                            .opacity(animateContent ? 1 : 0)
                            .offset(y: animateContent ? 0 : 20)
                            .animation(.easeInOut(duration: 0.8).delay(0.4), value: animateContent)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .safeAreaBarIfAvailable {
                ActionButton(Loc.Onboarding.continue, style: .borderedProminent) {
                    viewModel.navigate(to: .userType)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
            }
            .onAppear {
                withAnimation {
                    animateContent = true
                    animateIcon = true
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isTextFieldFocused = true
                }
            }
        }
        
        private var backgroundGradient: some View {
            LinearGradient(
                colors: [
                    Color.purple.opacity(0.08),
                    Color.pink.opacity(0.05),
                    Color.systemBackground
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}
