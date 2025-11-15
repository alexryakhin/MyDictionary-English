//
//  OnboardingPrivacyView.swift
//  My Dictionary
//
//  Created by GPT-5.1 Codex on 11/15/25.
//

import SwiftUI

extension OnboardingFlow {
    struct PrivacyView: View {
        @ObservedObject var viewModel: OnboardingFlow.ViewModel
        @Environment(\.openURL) private var openURL
        @State private var animateContent = false

        var body: some View {
            ScrollView {
                VStack(spacing: 24) {
                    Spacer()
                        .frame(height: 20)

                    Image(.illustrationSelection)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 220)
                        .scaleEffect(animateContent ? 1.0 : 0.8)
                        .animation(.spring(response: 0.9, dampingFraction: 0.8), value: animateContent)

                    VStack(spacing: 12) {
                        Text(Loc.Onboarding.aiPrivacyTitle)
                            .font(.system(.title, design: .rounded, weight: .bold))
                            .multilineTextAlignment(.center)
                            .opacity(animateContent ? 1 : 0)
                            .offset(y: animateContent ? 0 : 16)

                        Text(Loc.Onboarding.aiPrivacyDescription)
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .opacity(animateContent ? 1 : 0)
                            .offset(y: animateContent ? 0 : 16)
                    }
                    .padding(.horizontal, 16)
                    .animation(.easeInOut(duration: 0.8).delay(0.15), value: animateContent)

                    VStack(spacing: 16) {
                        SelectableCard(
                            title: Loc.Onboarding.aiPrivacyAllowTitle,
                            subtitle: Loc.Onboarding.aiPrivacyAllowDescription,
                            icon: "wand.and.stars",
                            isSelected: viewModel.aiPersonalizationAllowed == true
                        ) {
                            viewModel.updateAIPersonalizationConsent(true)
                        }

                        SelectableCard(
                            title: Loc.Onboarding.aiPrivacySkipTitle,
                            subtitle: Loc.Onboarding.aiPrivacySkipDescription,
                            icon: "hand.raised",
                            isSelected: viewModel.aiPersonalizationAllowed == false
                        ) {
                            viewModel.updateAIPersonalizationConsent(false)
                        }
                    }
                    .padding(.horizontal, 16)

                    VStack(spacing: 8) {
                        Text(Loc.Onboarding.aiPrivacyFooter)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)

                        Button {
                            openURL(GlobalConstant.privacyPolicy)
                        } label: {
                            Label(
                                Loc.Onboarding.aiPrivacyPolicyLink,
                                systemImage: "arrow.up.right.square"
                            )
                            .font(.footnote.weight(.semibold))
                        }
                    }
                    .padding(.horizontal, 16)

                    Spacer()
                        .frame(height: 20)
                }
                .padding(.vertical, 12)
            }
            .withGradientBackground()
            .safeAreaBarIfAvailable {
                ActionButton(Loc.Onboarding.continue, style: .borderedProminent) {
                    viewModel.navigate(to: .streak)
                }
                .disabled(viewModel.aiPersonalizationAllowed == nil)
                .padding(vertical: 12, horizontal: 16)
            }
            .onAppear {
                logInfo("[OnboardingPrivacyView] Appeared – consent=\(String(describing: viewModel.aiPersonalizationAllowed))")
                withAnimation {
                    animateContent = true
                }
            }
        }
    }
}

