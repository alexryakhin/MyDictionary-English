//
//  StreakCard.swift
//  My Dictionary
//
//  Created by Assistant on 8/25/25.
//

import SwiftUI

struct StreakCard: View {
    let streak: Int

    var body: some View {
        HStack(spacing: 12) {
            // Flame icon
            Image(systemName: "flame.fill")
                .font(.largeTitle)
                .foregroundStyle(.orange)

            // Streak text
            VStack(alignment: .leading, spacing: 4) {
                Text("\(streak)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)

                Text(Loc.Analytics.dayStreak)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .clippedWithPaddingAndBackground(
            Color.orange.opacity(0.15),
            in: .rect(cornerRadius: 16)
        )
        .glassBackgroundEffectIfAvailable(in: .rect(cornerRadius: 16))
    }
}

#Preview {
    VStack(spacing: 16) {
        StreakCard(streak: 7)
        StreakCard(streak: 0)
        StreakCard(streak: 365)
    }
    .padding()
    .background(Color.systemGroupedBackground)
}
