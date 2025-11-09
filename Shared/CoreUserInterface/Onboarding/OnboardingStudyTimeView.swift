//
//  OnboardingStudyTimeView.swift
//  My Dictionary
//
//  Created by Alexander Riakhin on 10/17/25.
//

import SwiftUI

extension OnboardingFlow {
    struct StudyTimeView: View {
        @ObservedObject var viewModel: OnboardingFlow.ViewModel
        @State private var animateContent = false
        @State private var showCards = false

        var body: some View {
            ScrollView {
                VStack(spacing: 32) {
                    Spacer()
                        .frame(height: 20)

                    // Animated illustration
                    Image(.illustrationTime)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 240)
                        .scaleEffect(animateContent ? 1.0 : 0.5)
                        .animation(.spring(response: 1.0, dampingFraction: 0.8), value: animateContent)

                    Text(Loc.Onboarding.whenDoYouPreferToStudy)
                        .font(.system(.title, design: .rounded, weight: .bold))
                        .multilineTextAlignment(.center)
                        .opacity(animateContent ? 1 : 0)
                        .offset(y: animateContent ? 0 : 20)
                        .animation(.easeInOut(duration: 0.8).delay(0.2), value: animateContent)
                        .padding(.horizontal, 16)

                    LazyVGrid(
                        columns: [
                            GridItem(.flexible(), spacing: 16),
                            GridItem(.flexible(), spacing: 16)
                        ],
                        spacing: 16
                    ) {
                        ForEach(Array(StudyTime.allCases.enumerated()), id: \.element) { index, studyTime in
                            SelectableCard(
                                title: studyTime.displayName,
                                subtitle: studyTime.timeRange,
                                icon: studyTime.icon,
                                isSelected: viewModel.preferredStudyTime == studyTime
                            ) {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                    logInfo("[OnboardingStudyTimeView] Selected studyTime=\(studyTime.rawValue)")
                                    viewModel.preferredStudyTime = studyTime
                                }
                            }
                            .opacity(showCards ? 1 : 0)
                            .offset(y: showCards ? 0 : 30)
                            .animation(.easeInOut(duration: 0.6).delay(0.4 + Double(index) * 0.15), value: showCards)
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .padding(vertical: 12, horizontal: 16)
            }
            .withGradientBackground()
            .safeAreaBarIfAvailable {
                ActionButton(Loc.Onboarding.continue, style: .borderedProminent) {
                    logInfo("[OnboardingStudyTimeView] Continue tapped – preferredStudyTime=\(viewModel.preferredStudyTime.rawValue)")
                    viewModel.navigate(to: .streak)
                }
                .padding(vertical: 12, horizontal: 16)
            }
            .onAppear {
                logInfo("[OnboardingStudyTimeView] Appeared – preferredStudyTime=\(viewModel.preferredStudyTime.rawValue)")
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
