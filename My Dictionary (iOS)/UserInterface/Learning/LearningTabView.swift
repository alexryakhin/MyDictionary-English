//
//  LearningTabView.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/9/25.
//

import SwiftUI

struct LearningTabView: View {
    @State private var showingOnboarding = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
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
                            systemImage: "play.circle.fill",
                            style: .bordered
                        ) {
                            // TODO: Implement continue learning
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .padding(.horizontal, 16)
        }
        .groupedBackground()
        .navigation(
            title: Loc.Learning.Tabbar.learn,
            mode: .large,
            showsBackButton: false
        )
        .sheet(isPresented: $showingOnboarding) {
            LearningOnboardingView()
        }
    }
}

#Preview {
    LearningTabView()
}
