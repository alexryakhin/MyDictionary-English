//
//  QuizResultsView.swift
//  My Dictionary
//
//  Created by Alexander Riakhin on 8/15/25.
//

import SwiftUI

struct QuizResultsView: View {

    struct Model: Hashable {
        let score: Int
        let correctAnswers: Int
        let wordsPlayed: Int
        let bestStreak: Int
    }

    let model: Model
    let onRestart: VoidHandler
    let onFinish: VoidHandler

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

                    Text(Loc.Quizzes.greatJobCompletedDefinitionQuiz)
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
                            Text("\(model.correctAnswers)/\(model.wordsPlayed)")
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
                            Text("\(Int((Double(model.correctAnswers) / Double(model.wordsPlayed)) * 100))%")
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
                ActionButton(Loc.Actions.tryAgain, systemImage: "arrow.clockwise", style: .borderedProminent) {
                    onRestart()
                }
                ActionButton(Loc.Quizzes.backToQuizzes, systemImage: "chevron.left") {
                    onFinish()
                }
            }
            .padding(.horizontal, 32)

            Spacer()
        }
        .groupedBackground()
    }
}

#Preview {
    QuizResultsView(
        model: .init(score: 50, correctAnswers: 10, wordsPlayed: 10, bestStreak: 10),
        onRestart: {},
        onFinish: {}
    )
}
