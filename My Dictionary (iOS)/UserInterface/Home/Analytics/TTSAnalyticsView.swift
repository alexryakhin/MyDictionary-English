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
            
            // Monthly Speechify Usage Section
            if subscriptionService.isProUser {
                VStack(spacing: 8) {
                    HStack {
                        Text("Speechify Monthly Usage")
                            .font(.headline)
                            .fontWeight(.semibold)
                        Spacer()
                        
                        // Sync status indicator
                        if usageTracker.isSyncing {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.caption)
                        }
                    }
                    
                    VStack(spacing: 4) {
                        HStack {
                            Text("Used:")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(usageTracker.getCurrentMonthSpeechifyUsage().formatted()) / \(usageTracker.getMonthlySpeechifyLimit().formatted()) characters")
                                .fontWeight(.medium)
                        }
                        
                        ProgressView(value: usageTracker.getSpeechifyUsagePercentage(), total: 100)
                            .progressViewStyle(LinearProgressViewStyle(tint: usageTracker.getSpeechifyUsagePercentage() > 80 ? .orange : .blue))
                        
                        HStack {
                            Text("Remaining:")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(usageTracker.getRemainingSpeechifyCharacters().formatted()) characters")
                                .fontWeight(.medium)
                                .foregroundColor(usageTracker.getRemainingSpeechifyCharacters() < 5000 ? .orange : .primary)
                        }
                    }
                    .padding()
                    .background(Color.secondarySystemGroupedBackground)
                    .cornerRadius(12)
                    
                    // Manual sync buttons
                    HStack(spacing: 8) {
                        Button("Sync to Cloud") {
                            Task {
                                await usageTracker.syncToFirebase()
                            }
                        }
                        .buttonStyle(.bordered)
                        .disabled(usageTracker.isSyncing)
                        
                        Button("Sync from Cloud") {
                            Task {
                                await usageTracker.syncFromFirebase()
                            }
                        }
                        .buttonStyle(.bordered)
                        .disabled(usageTracker.isSyncing)
                    }
                    .font(.caption)
                }
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
