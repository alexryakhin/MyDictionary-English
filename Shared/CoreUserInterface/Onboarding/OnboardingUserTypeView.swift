//
//  OnboardingUserTypeView.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import SwiftUI

extension OnboardingFlow {
    struct UserTypeView: View {
        @ObservedObject var viewModel: OnboardingFlow.ViewModel
        @State private var animateContent = false
        @State private var showCards = false

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
                    Image(.illustrationDescription)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 200)
                        .scaleEffect(animateContent ? 1.0 : 0.5)
                        .animation(.spring(response: 1.0, dampingFraction: 0.8), value: animateContent)

                    // Title
                    Text(Loc.Onboarding.whichBestDescribesYou)
                        .font(.system(.title, design: .rounded, weight: .bold))
                        .multilineTextAlignment(.center)
                        .opacity(animateContent ? 1 : 0)
                        .offset(y: animateContent ? 0 : 20)
                        .animation(.easeInOut(duration: 0.8).delay(0.2), value: animateContent)
                        .padding(.horizontal, 16)

                    // Content
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(Array(UserType.allCases.enumerated()), id: \.element) { index, userType in
                            SelectableCard(
                                title: userType.displayName,
                                subtitle: userType.description,
                                icon: userType.icon,
                                isSelected: viewModel.selectedUserType == userType
                            ) {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                    viewModel.selectedUserType = userType
                                }
                            }
                            .opacity(showCards ? 1 : 0)
                            .offset(y: showCards ? 0 : 30)
                            .animation(.easeInOut(duration: 0.6).delay(0.4 + Double(index) * 0.1), value: showCards)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(vertical: 12, horizontal: 16)
            }
            .withGradientBackground()
            .safeAreaBarIfAvailable {
                ActionButton(Loc.Onboarding.continue, style: .borderedProminent) {
                    viewModel.navigate(to: .ageGroup)
                }
                .disabled(viewModel.selectedUserType == nil)
                .padding(vertical: 12, horizontal: 16)
            }
            .onAppear {
                withAnimation {
                    animateContent = true
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    showCards = true
                }
            }
        }
    }
}
