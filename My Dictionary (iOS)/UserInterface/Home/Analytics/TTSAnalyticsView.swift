//
//  TTSAnalyticsView.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/9/25.
//

import SwiftUI

struct TTSAnalyticsView: View {
    @StateObject private var usageTracker = TTSUsageTracker.shared
    @StateObject private var subscriptionService = SubscriptionService.shared
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                StatCard(
                    title: "Characters Used",
                    value: usageTracker.totalCharactersFormatted,
                    icon: "textformat.abc"
                )
                
                StatCard(
                    title: "TTS Sessions",
                    value: usageTracker.totalSessionsFormatted,
                    icon: "play.circle"
                )
            }
            
            HStack(spacing: 12) {
                StatCard(
                    title: "Time Saved",
                    value: usageTracker.timeSaved,
                    icon: "clock"
                )
                
                StatCard(
                    title: "Favorite Voice",
                    value: usageTracker.favoriteVoice,
                    icon: "person.circle"
                )
            }
            
            if subscriptionService.isProUser {
                ActionButton(
                    "Open TTS Dashboard",
                    systemImage: "speaker.wave.3.fill",
                    style: .bordered
                ) {
                    NavigationManager.shared.navigate(to: .ttsDashboard)
                }
            } else {
                ActionButton(
                    "Upgrade to Pro for TTS Dashboard",
                    systemImage: "crown.fill",
                    style: .borderedProminent
                ) {
                    PaywallService.shared.isShowingPaywall = true
                }
            }
        }
    }
}

#Preview {
    TTSAnalyticsView()
        .padding()
}
