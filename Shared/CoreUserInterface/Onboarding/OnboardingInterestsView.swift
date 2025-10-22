//
//  OnboardingInterestsView.swift
//  My Dictionary
//
//  Created by Alexander Riakhin on 10/17/25.
//

import SwiftUI
import Flow

extension OnboardingFlow {
    struct InterestsView: View {
        @ObservedObject var viewModel: OnboardingFlow.ViewModel
        @State private var animateContent = false
        @State private var showChips = false
        
        private let columns = [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ]
        
        var body: some View {
            ScrollView {
                VStack(spacing: 32) {
                    Spacer()
                        .frame(height: 20)

                    // Animated illustration
                    Image(.illustrationSelection)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 240)
                        .scaleEffect(animateContent ? 1.0 : 0.5)
                        .animation(.spring(response: 1.0, dampingFraction: 0.8), value: animateContent)

                    VStack(spacing: 12) {
                        Text(Loc.Onboarding.whatTopicsInterestYou)
                            .font(.system(.title, design: .rounded, weight: .bold))
                            .multilineTextAlignment(.center)

                        Text(Loc.Onboarding.select2To5Interests)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .opacity(animateContent ? 1 : 0)
                    .offset(y: animateContent ? 0 : 20)
                    .animation(.easeInOut(duration: 0.8).delay(0.2), value: animateContent)
                    .padding(.horizontal, 16)

                    HFlow(alignment: .top, spacing: 12) {
                        ForEach(Array(Interest.allCases.enumerated()), id: \.element) { index, interest in
                            SelectableChip(
                                title: interest.displayName,
                                icon: interest.icon,
                                isSelected: viewModel.selectedInterests.contains(interest)
                            ) {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                    toggleInterest(interest)
                                }
                            }
                            .opacity(showChips ? 1 : 0)
                            .scaleEffect(showChips ? 1.0 : 0.8)
                            .animation(.easeInOut(duration: 0.5).delay(0.4 + Double(index) * 0.05), value: showChips)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(vertical: 12, horizontal: 16)
            }
            .withGradientBackground()
            .safeAreaBarIfAvailable {
                ActionButton(Loc.Onboarding.continue, style: .borderedProminent) {
                    viewModel.navigate(to: .studyIntensity)
                }
                .disabled(!(viewModel.selectedInterests.count >= 2 && viewModel.selectedInterests.count <= 5))
                .padding(vertical: 12, horizontal: 16)
            }
            .onAppear {
                withAnimation {
                    animateContent = true
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    showChips = true
                }
            }
        }
        
        private func toggleInterest(_ interest: Interest) {
            if viewModel.selectedInterests.contains(interest) {
                viewModel.selectedInterests.remove(interest)
            } else if viewModel.selectedInterests.count < 5 {
                viewModel.selectedInterests.insert(interest)
            }
        }
    }
}
