//
//  QuizResultsDetailView.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/9/25.
//

import SwiftUI

enum QuizResultsList {
    struct ContentView: View {

        @StateObject private var viewModel = AnalyticsViewModel()
        @Environment(\.dismiss) private var dismiss

        var body: some View {
            ScrollView {
                CustomSectionView(header: Loc.Quizzes.allResults, hPadding: .zero) {
                    if viewModel.quizSessions.isEmpty {
                        ContentUnavailableView(
                            Loc.Analytics.noQuizResultsYet,
                            systemImage: "chart.bar",
                            description: Text(Loc.Analytics.completeFirstQuizResults)
                        )
                        .listRowBackground(Color.clear)
                    } else {
                        ListWithDivider(viewModel.quizSessions) { session in
                            SessionRow(session: session)
                                .id(session.id)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .if(isPad) { view in
                    view
                        .frame(maxWidth: 550, alignment: .center)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .groupedBackground()
            .navigation(title: Loc.Navigation.quizResults, mode: .inline, showsBackButton: true)
            .onAppear {
                AnalyticsService.shared.logEvent(.quizResultsDetailOpened)
                viewModel.loadData()
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
                        Text(session.quiz?.title ?? Loc.Quizzes.QuizResults.quiz)
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
                        title: Loc.Quizzes.QuizResults.accuracy,
                        value: "\(Int(session.accuracy * 100))%",
                        icon: "target",
                        color: .blue
                    )

                    StatItem(
                        title: Loc.Quizzes.QuizResults.correct,
                        value: "\(session.correctAnswers)/\(session.totalWords)",
                        icon: "checkmark.circle",
                        color: .accent
                    )

                    StatItem(
                        title: Loc.Quizzes.QuizResults.duration,
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
