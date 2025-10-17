//
//  OnboardingStudyIntensityView.swift
//  My Dictionary
//
//  Created by Alexander Riakhin on 10/17/25.
//

import SwiftUI

extension OnboardingFlow {
    struct StudyIntensityView: View {
        @ObservedObject var viewModel: OnboardingFlow.ViewModel
        @State private var animateContent = false

        private let weeklyGoals = [50, 100, 200, 300]

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
                                .fill(Color.red.opacity(0.1))
                                .frame(width: 120, height: 120)
                            
                            Image(systemName: "gauge.high")
                                .font(.system(size: 50))
                                .foregroundStyle(Color.red)
                                .scaleEffect(animateContent ? 1.0 : 0.5)
                        }
                        .animation(.spring(response: 1.0, dampingFraction: 0.8), value: animateContent)
                        
                        Text(Loc.Onboarding.howManyWordsPerWeek)
                            .font(.system(.title, design: .rounded, weight: .bold))
                            .multilineTextAlignment(.center)
                            .opacity(animateContent ? 1 : 0)
                            .offset(y: animateContent ? 0 : 20)
                            .animation(.easeInOut(duration: 0.8).delay(0.2), value: animateContent)
                            .padding(.horizontal, 16)
                        
                        Picker("Weekly Goal", selection: $viewModel.weeklyWordGoal) {
                            ForEach(weeklyGoals, id: \.self) { goal in
                                Text(Loc.Onboarding.wordsPerWeek(goal))
                                    .font(.caption)
                                    .tag(goal)
                            }
                        }
                        .pickerStyle(.wheel)
                        .padding(.vertical, -16)
                        .opacity(animateContent ? 1 : 0)
                        .scaleEffect(animateContent ? 1.0 : 0.95)
                        .animation(.easeInOut(duration: 0.8).delay(0.4), value: animateContent)
                    }
                    .padding(vertical: 12, horizontal: 16)
                }
            }
            .safeAreaBarIfAvailable {
                VStack(spacing: 12) {
                    Text(Loc.Onboarding.estimatedDailyTime(viewModel.weeklyWordGoal / 7 * 2))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    ActionButton(Loc.Onboarding.continue, style: .borderedProminent) {
                        viewModel.navigate(to: .studyTime)
                    }
                }
                .padding(vertical: 12, horizontal: 16)
            }
            .onAppear {
                withAnimation {
                    animateContent = true
                }
            }
        }
        
        private var backgroundGradient: some View {
            LinearGradient(
                colors: [
                    Color.red.opacity(0.08),
                    Color.orange.opacity(0.05),
                    Color.systemBackground
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}
