//
//  OnboardingAgeGroupView.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import SwiftUI

extension OnboardingFlow {
    struct AgeGroupView: View {
        @ObservedObject var viewModel: OnboardingFlow.ViewModel
        @State private var animateContent = false
        @State private var showItems = false

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
                                .fill(Color.green.opacity(0.1))
                                .frame(width: 120, height: 120)
                            
                            Image(systemName: "person.3.fill")
                                .font(.system(size: 50))
                                .foregroundStyle(Color.green)
                                .scaleEffect(animateContent ? 1.0 : 0.5)
                        }
                        .animation(.spring(response: 1.0, dampingFraction: 0.8), value: animateContent)
                        
                        // Title
                        Text(Loc.Onboarding.whatsYourAgeGroup)
                            .font(.system(.title, design: .rounded, weight: .bold))
                            .multilineTextAlignment(.center)
                            .opacity(animateContent ? 1 : 0)
                            .offset(y: animateContent ? 0 : 20)
                            .animation(.easeInOut(duration: 0.8).delay(0.2), value: animateContent)
                            .padding(.horizontal, 32)
                        
                        // Content
                        VStack(spacing: 12) {
                            ForEach(Array(AgeGroup.allCases.enumerated()), id: \.element) { index, ageGroup in
                                Button(action: {
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                        viewModel.selectedAgeGroup = ageGroup
                                    }
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
                                                .transition(.scale.combined(with: .opacity))
                                        }
                                    }
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(viewModel.selectedAgeGroup == ageGroup
                                                  ? Color.accentColor.opacity(0.1)
                                                  : Color.systemBackground)
                                            .shadow(color: .label.opacity(0.05), radius: 8, x: 0, y: 4)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(viewModel.selectedAgeGroup == ageGroup
                                                    ? Color.accentColor
                                                    : Color.clear, lineWidth: 2)
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                                .opacity(showItems ? 1 : 0)
                                .offset(x: showItems ? 0 : -30)
                                .animation(.easeInOut(duration: 0.6).delay(0.4 + Double(index) * 0.1), value: showItems)
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .safeAreaBarIfAvailable {
                ActionButton(Loc.Onboarding.continue, style: .borderedProminent) {
                    viewModel.navigate(to: .goals)
                }
                .disabled(viewModel.selectedAgeGroup == nil)
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
            }
            .onAppear {
                withAnimation {
                    animateContent = true
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    showItems = true
                }
            }
        }
        
        private var backgroundGradient: some View {
            LinearGradient(
                colors: [
                    Color.green.opacity(0.08),
                    Color.accentColor.opacity(0.05),
                    Color.systemBackground
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}
