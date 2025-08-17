//
//  SharedWordDifficultyStatsView.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import SwiftUI

struct SharedWordDifficultyStatsView: View {
    let word: SharedWord

    var body: some View {
        ScrollViewWithCustomNavBar {
            VStack(spacing: 16) {
                individualRatingsSection
            }
            .padding(12)
        } navigationBar: {
            NavigationBarView(title: "Difficulty Statistics")
        }
        .groupedBackground()
        .onAppear {
            AnalyticsService.shared.logEvent(.sharedWordStatsViewed)
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        ForEach(0..<3) { _ in
            ShimmerView(height: 60)
        }
    }

    // MARK: - Individual Ratings Section

    private var individualRatingsSection: some View {
        CustomSectionView(
            header: "Individual Ratings",
            headerFontStyle: .regular,
            footer: "How other users rate this word's difficulty"
        ) {
            if word.difficulties.isEmpty {
                emptyStateView
                    .padding(.bottom, 12)
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(Array(word.difficulties.keys.sorted()), id: \.self) { userEmail in
                        UserDifficultyRow(
                            userEmail: userEmail,
                            score: word.difficulties[userEmail] ?? 0
                        )
                    }
                }
                .padding(.bottom, 12)
            }
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        ContentUnavailableView(
            "No difficulty ratings yet",
            systemImage: "chart.bar.doc.horizontal",
                            description: Text(Loc.SharedDictionaries.beFirstToRateDifficulty.localized)
        )
    }
}

// MARK: - User Difficulty Row

struct UserDifficultyRow: View {
    let userEmail: String
    let score: Int
    var difficulty: Difficulty {
        Difficulty(score: score)
    }

    var body: some View {
        HStack(spacing: 12) {
            // User info and difficulty
            VStack(alignment: .leading, spacing: 4) {
                Text(userEmail)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)

                Text(Loc.SharedDictionaries.score.localized(score))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Difficulty badge
            TagView(
                text: difficulty.displayName,
                color: difficulty.color
            )
        }
        .padding(12)
        .background(Color.tertiarySystemGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
