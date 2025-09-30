//
//  QuizResultsView.swift
//  My Dictionary
//
//  Created by Alexander Riakhin on 8/15/25.
//

import SwiftUI

struct QuizResultsView<AdditionalAction: View>: View {

    struct Model: Hashable {
        let quiz: Quiz
        let score: Int
        let correctAnswers: Int
        let itemsPlayed: Int
        let accuracyContributions: Double
        let bestStreak: Int
    }

    let model: Model
    let additionalAction: () -> AdditionalAction

    init(
        model: Model,
        @ViewBuilder additionalAction: @escaping () -> AdditionalAction = { EmptyView() }
    ) {
        self.model = model
        self.additionalAction = additionalAction
    }

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
                    Text(Loc.Quizzes.quizComplete)
                        .font(.title)
                        .fontWeight(.bold)

                    Text(model.quiz.completionDescription)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                // Score Card
                VStack(spacing: 16) {
                    Text(Loc.Quizzes.yourResults)
                        .font(.headline)
                        .fontWeight(.semibold)

                    VStack(spacing: 12) {
                        HStack {
                            Text(Loc.Quizzes.finalScore)
                            Spacer()
                            Text("\(model.score)")
                                .fontWeight(.bold)
                                .foregroundStyle(.accent)
                        }

                        HStack {
                            Text(Loc.Quizzes.correctAnswers)
                            Spacer()
                            Text("\(model.correctAnswers)/\(model.itemsPlayed)")
                                .fontWeight(.medium)
                        }

                        HStack {
                            Text(Loc.Quizzes.bestStreak)
                            Spacer()
                            Text("\(model.bestStreak)")
                                .fontWeight(.medium)
                                .foregroundStyle(.orange)
                        }

                        HStack {
                            Text(Loc.Quizzes.accuracy)
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
                .shadow(color: .label.opacity(0.05), radius: 8, x: 0, y: 2)

                additionalAction()
            }
            .padding(.horizontal, 32)

            Spacer()
        }
        .background(
            Color.systemGroupedBackground
                .displayConfetti(isActive: .constant(calculatedAccuracy() >= 80))
                .ignoresSafeArea()
        )
    }

    private func calculatedAccuracy() -> Double {
        guard model.accuracyContributions != .zero else {
            return (Double(model.correctAnswers) / Double(model.itemsPlayed)) * 100
        }

        let wordsPlayedCount = Double(model.itemsPlayed)

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
            itemsPlayed: 10,
            accuracyContributions: .zero,
            bestStreak: 10
        )
    )
}
