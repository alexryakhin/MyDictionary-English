//
//  QuizResultsView.swift
//  My Dictionary
//
//  Created by Alexander Riakhin on 8/15/25.
//

import SwiftUI

struct QuizResultsView: View {

    struct Model: Hashable {
        let quiz: Quiz
        let score: Int
        let correctAnswers: Int
        let wordsPlayed: Int
        let accuracyContributions: Double
        let bestStreak: Int
    }

    let model: Model
    let onRestart: VoidHandler

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 24) {
                // Success Icon
                ZStack {
                    Circle()
                        .fill(.accent.gradient)
                        .frame(width: 80, height: 80)

                    Image(systemName: "checkmark")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                }

                VStack(spacing: 12) {
                    Text("Quiz Complete!")
                        .font(.title)
                        .fontWeight(.bold)

                    Text(model.quiz.completionDescription)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                // Score Card
                VStack(spacing: 16) {
                    Text("Your Results")
                        .font(.headline)
                        .fontWeight(.semibold)

                    VStack(spacing: 12) {
                        HStack {
                            Text("Final Score")
                            Spacer()
                            Text("\(model.score)")
                                .fontWeight(.bold)
                                .foregroundStyle(.accent)
                        }

                        HStack {
                            Text("Correct Answers")
                            Spacer()
                            Text("\(model.correctAnswers)/\(model.wordsPlayed)")
                                .fontWeight(.medium)
                        }

                        HStack {
                            Text("Best Streak")
                            Spacer()
                            Text("\(model.bestStreak)")
                                .fontWeight(.medium)
                                .foregroundStyle(.orange)
                        }

                        HStack {
                            Text("Accuracy")
                            Spacer()
                            Text("\(Int(calculatedAccuracy()))%")
                                .fontWeight(.medium)
                                .foregroundStyle(.accent)
                        }
                    }
                    .font(.body)
                }
                .padding(24)
                .clippedWithBackground()
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
            }
            .padding(.horizontal, 32)

            Spacer()

            VStack(spacing: 12) {
                ActionButton("Try Again", systemImage: "arrow.clockwise", style: .borderedProminent) {
                    onRestart()
                }
            }
            .padding(.horizontal, 32)

            Spacer()
        }
        .groupedBackground()
    }

    private func calculatedAccuracy() -> Double {
        guard model.accuracyContributions != .zero else {
            return (Double(model.correctAnswers) / Double(model.wordsPlayed)) * 100
        }

        let wordsPlayedCount = Double(model.wordsPlayed)

        if wordsPlayedCount == 0 {
            return 0.0
        }

        // Calculate accuracy based on contributions
        let averageAccuracy = model.accuracyContributions / wordsPlayedCount
        return averageAccuracy * 100
    }
}

#Preview {
    QuizResultsView(
        model: .init(
            quiz: .chooseDefinition,
            score: 50,
            correctAnswers: 10,
            wordsPlayed: 10,
            accuracyContributions: .zero,
            bestStreak: 10
        ),
        onRestart: {
        }
    )
}
