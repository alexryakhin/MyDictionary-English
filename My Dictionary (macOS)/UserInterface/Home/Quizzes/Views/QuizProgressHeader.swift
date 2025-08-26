//
//  QuizProgressHeader.swift
//  My Dictionary
//
//  Created by Alexander Riakhin on 8/16/25.
//

import SwiftUI

struct QuizProgressHeader: View {

    struct Model {
        let itemsPlayed: Int
        let totalQuestions: Int
        let currentStreak: Int
        let score: Int
        let bestStreak: Int
    }

    let model: Model

    var body: some View {
        VStack(spacing: 6) {
            // Progress Bar
            ProgressView(value: Double(model.itemsPlayed), total: Double(model.totalQuestions))
                .progressViewStyle(.linear)

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(Loc.Quizzes.progressFormat(model.itemsPlayed, model.totalQuestions))
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if model.currentStreak > 0 {
                        Text(Loc.Quizzes.streakFormat(model.currentStreak))
                            .font(.caption)
                            .foregroundStyle(.orange)
                            .fontWeight(.medium)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(Loc.Quizzes.scoreFormat(model.score))
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.blue)

                    Text(Loc.Quizzes.bestFormat(model.bestStreak))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}
