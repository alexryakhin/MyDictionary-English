//
//  TTSAnalyticsView.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/9/25.
//

import SwiftUI

struct TTSAnalyticsView: View {
    @StateObject private var ttsPlayer = TTSPlayer.shared
    @StateObject private var usageTracker = TTSUsageTracker.shared

    var body: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2),
            spacing: 12
        ) {
            StatCard(
                title: "Characters Used",
                value: usageTracker.totalCharactersFormatted,
                icon: "textformat.abc",
                color: .blue
            )

            StatCard(
                title: "Sessions",
                value: usageTracker.totalSessionsFormatted,
                icon: "play.circle",
                color: .accent
            )

            StatCard(
                title: "Favorite Voice",
                value: usageTracker.favoriteVoice,
                icon: "person.circle",
                color: .purple
            )

            StatCard(
                title: "Time Saved",
                value: usageTracker.timeSaved,
                icon: "clock",
                color: .orange
            )
        }
    }

    struct StatCard: View {
        let title: String
        let value: String
        let icon: String
        let color: Color

        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: icon)
                        .foregroundStyle(color)
                        .font(.title2)

                    Spacer()
                }

                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)

                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(vertical: 12, horizontal: 16)
            .clippedWithBackground(Color.tertiarySystemGroupedBackground, cornerRadius: 16)
        }
    }
}

#Preview {
    TTSAnalyticsView()
        .padding()
}
