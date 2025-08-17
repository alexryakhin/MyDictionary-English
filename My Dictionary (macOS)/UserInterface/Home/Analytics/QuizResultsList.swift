//
//  QuizResultsDetailView.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/9/25.
//

import SwiftUI

enum QuizResultsList {
    struct ContentView: View {
        @Environment(\.dismiss) private var dismiss

        let quizSessions: [CDQuizSession]

        var body: some View {
            ScrollViewWithCustomNavBar {
                CustomSectionView(header: "All Results", hPadding: .zero) {
                    if quizSessions.isEmpty {
                        ContentUnavailableView(
                            "No Quiz Results Yet",
                            systemImage: "chart.bar",
                            description: Text(Loc.Analytics.completeFirstQuizResults.localized)
                        )
                        .listRowBackground(Color.clear)
                    } else {
                        ListWithDivider(quizSessions) { session in
                            SessionRow(session: session)
                                .id(session.id)
                        }
                    }
                }
                .padding(12)
            } navigationBar: {
                NavigationBarView(title: "Quiz Results")
            }
            .groupedBackground()
            .onAppear {
                AnalyticsService.shared.logEvent(.quizResultsDetailOpened)
            }
        }
    }

    struct SessionRow: View {
        let session: CDQuizSession

        var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                // Header with date and quiz type
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(session.quizType?.capitalized ?? "Quiz")
                            .font(.headline)
                            .fontWeight(.semibold)

                        if let date = session.date {
                            Text(date.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()

                    // Score badge
                    TagView(
                        text: session.score.formatted(),
                        color: scoreColor,
                        size: .large,
                        style: .selected
                    )
                }

                // Stats row
                HStack(spacing: 16) {
                    StatItem(
                        title: "Accuracy",
                        value: "\(Int(session.accuracy * 100))%",
                        icon: "target",
                        color: .blue
                    )

                    StatItem(
                        title: "Correct",
                        value: "\(session.correctAnswers)/\(session.totalWords)",
                        icon: "checkmark.circle",
                        color: .accent
                    )

                    StatItem(
                        title: "Duration",
                        value: formatDuration(session.duration),
                        icon: "clock",
                        color: .orange
                    )
                }
            }
            .padding(vertical: 12, horizontal: 16)
        }

        private var scoreColor: Color {
            let accuracy = session.accuracy
            if accuracy >= 0.8 { return .accent }
            if accuracy >= 0.6 { return .orange }
            return .red
        }

        private func formatDuration(_ duration: TimeInterval) -> String {
            let minutes = Int(duration / 60)
            let seconds = Int(duration.truncatingRemainder(dividingBy: 60))
            return "\(minutes):\(String(format: "%02d", seconds))"
        }
    }

    struct StatItem: View {
        let title: String
        let value: String
        let icon: String
        let color: Color

        var body: some View {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(color)

                Text(value)
                    .font(.caption)
                    .fontWeight(.medium)

                Text(title)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
        }
    }
}
