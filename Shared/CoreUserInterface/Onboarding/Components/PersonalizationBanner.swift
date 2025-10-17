//
//  PersonalizationBanner.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import SwiftUI

struct PersonalizationBanner: View {
    @StateObject private var onboardingService = OnboardingService.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(Loc.Onboarding.completeYourProfile)
                        .font(.headline)
                    
                    Text(Loc.Onboarding.personalizeYourLearning)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(Loc.Onboarding.takes2Minutes)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()

                Button(action: {
                    onboardingService.showBanner = false
                    AnalyticsService.shared.logEvent(.personalizationBannerDismissed)
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                        .padding(8)
                }
            }

            ActionButton(Loc.Onboarding.personalizeNow, style: .borderedProminent) {
                onboardingService.showOnboarding = true
                AnalyticsService.shared.logEvent(.personalizationBannerTapped)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.accentColor.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.accentColor.opacity(0.3), lineWidth: 1)
        )
    }
}
