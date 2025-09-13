//
//  WelcomeOnboardingScreen.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/9/25.
//

import SwiftUI

struct WelcomeOnboardingScreen: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                Spacer(minLength: 40)
                
                // Welcome Section
                CustomSectionView(header: Loc.Learning.Onboarding.welcomeToLearning) {
                    VStack(spacing: 20) {
                        // Icon
                        Image(systemName: "book.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.accent)
                        
                        // Subtitle
                        Text(Loc.Learning.Onboarding.personalizedLanguageCourse)
                            .font(.title2)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        // Description
                        Text(Loc.Learning.Onboarding.letUsGetToKnowYou)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.vertical, 20)
                }
                
                // Features Section
                CustomSectionView(header: "What You'll Get") {
                    VStack(spacing: 16) {
                        FeatureRow(
                            icon: "brain.head.profile",
                            title: "AI-Powered Learning",
                            description: "Personalized lessons adapted to your needs"
                        )
                        
                        FeatureRow(
                            icon: "chart.line.uptrend.xyaxis",
                            title: "Progress Tracking",
                            description: "See your improvement with detailed analytics"
                        )
                        
                        FeatureRow(
                            icon: "person.2.fill",
                            title: "Interactive Practice",
                            description: "Practice with AI conversations and exercises"
                        )
                    }
                    .padding(.vertical, 8)
                }
                
                Spacer(minLength: 40)
            }
            .padding(.horizontal, 16)
        }
        .groupedBackground()
    }

    struct FeatureRow: View {
        let icon: String
        let title: String
        let description: String

        var body: some View {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.accent)
                    .frame(width: 30)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)

                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
            .padding(.vertical, 8)
        }
    }
}

#Preview {
    WelcomeOnboardingScreen()
}
