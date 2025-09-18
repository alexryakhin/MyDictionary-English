//
//  LearningTabView.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/9/25.
//

import SwiftUI

struct LearningTabView: View {
    @State private var showingOnboarding = false
    @State private var hasCompletedOnboarding = false
    
    var body: some View {
        VStack {
            if hasCompletedOnboarding {
                LearnMainView()
            } else {
                onboardingView
            }
        }
        .onAppear {
            checkOnboardingStatus()
        }
        .sheet(isPresented: $showingOnboarding) {
            LearningOnboardingView()
        }
    }
    
    private var onboardingView: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header Section
                CustomSectionView(header: Loc.Learning.Tabbar.learn) {
                    VStack(spacing: 20) {
                        Image(systemName: "book.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.accent)
                        
                        Text(Loc.Learning.Onboarding.letUsGetToKnowYou)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.vertical, 20)
                }
                
                // Action Buttons Section
                CustomSectionView(header: "Get Started") {
                    VStack(spacing: 16) {
                        ActionButton(
                            Loc.Learning.Onboarding.getStarted,
                            systemImage: "arrow.right.circle.fill",
                            style: .borderedProminent
                        ) {
                            showingOnboarding = true
                        }
                        
                        ActionButton(
                            "Continue Learning",
                            systemImage: "graduationcap.fill",
                            style: .bordered
                        ) {
                            // TODO: Implement continue learning
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .padding(16)
        }
        .groupedBackground()
        .navigation(
            title: Loc.Learning.Tabbar.learn,
            mode: .large,
            showsBackButton: false
        )
    }
    
    private func checkOnboardingStatus() {
        // Check if user has completed onboarding
        hasCompletedOnboarding = UserDefaults.standard.data(forKey: "learning_profile") != nil
    }
}

#Preview {
    LearningTabView()
}
