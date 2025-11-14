import SwiftUI

struct PronunciationPracticeQuizContentView: View {

    @StateObject private var viewModel: PronunciationPracticeQuizViewModel
    @Environment(\.dismiss) private var dismiss

    init(preset: QuizPreset) {
        self._viewModel = StateObject(wrappedValue: PronunciationPracticeQuizViewModel(preset: preset))
    }

    var body: some View {
        Group {
            switch viewModel.loadingState {
            case .loading, .generating:
                loadingView
            case .ready:
                quizBody
            case .error(let message):
                errorView(message: message)
            }
        }
        .groupedBackground()
        .navigation(
            title: Loc.Quizzes.QuizTypes.pronunciationPractice,
            trailingContent: {
                HeaderButton(Loc.Actions.exit) {
                    dismiss()
                }
            },
            bottomContent: {
                Text(Loc.Quizzes.PronunciationPractice.instructionsDescription)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        )
        .onDisappear {
            viewModel.handleDismissIfNeeded()
        }
        .onReceive(viewModel.dismissPublisher) {
            dismiss()
        }
    }

    @ViewBuilder
    private var quizBody: some View {
        if viewModel.isQuizComplete {
            resultsView
        } else if let config = viewModel.quizConfig {
            ScrollView {
                PronunciationQuizRecorderView(config: config)
                    .padding(vertical: 12, horizontal: 16)
                    .if(isPad) { view in
                        view
                            .frame(maxWidth: 620, alignment: .center)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
            }
        } else {
            loadingView
        }
    }

    private var resultsView: some View {
        ScrollView {
            VStack(spacing: 24) {
                QuizResultsView(
                    model: .init(
                        quiz: .pronunciationPractice,
                        score: viewModel.score,
                        correctAnswers: viewModel.correctAnswers,
                        itemsPlayed: viewModel.wordSummaries.count,
                        accuracyContributions: viewModel.totalAccuracyContribution,
                        bestStreak: viewModel.bestStreak
                    ),
                    showStreak: viewModel.showStreakAnimation,
                    currentDayStreak: viewModel.currentDayStreak,
                    additionalAction: { EmptyView() },
                    onFinish: {
                        dismiss()
                    }
                )
                .padding(.horizontal, 20)
                .if(isPad) { view in
                    view
                        .frame(maxWidth: 520, alignment: .center)
                        .frame(maxWidth: .infinity, alignment: .center)
                }

                if !viewModel.wordSummaries.isEmpty {
                    summarySection
                        .padding(.horizontal, 20)
                        .padding(.bottom, 24)
                        .if(isPad) { view in
                            view
                                .frame(maxWidth: 620, alignment: .center)
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                }
            }
        }
    }

    private var summarySection: some View {
        CustomSectionView(header: Loc.Quizzes.PronunciationPractice.reviewHeader, hPadding: .zero) {
            FormWithDivider {
                ForEach(Array(viewModel.wordSummaries.enumerated()), id: \.element.id) { index, summary in
                    CellWrapper(
                        "\(index + 1). \(summary.word)",
                        mainContent: {
                            Text(summary.sentence)
                                .foregroundStyle(.primary)
                        },
                        trailingContent: {
                            if let isCorrect = summary.isCorrect {
                                Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .foregroundStyle(isCorrect ? .green : .red)
                            }
                        }
                    )
                }
            }
        }
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            AICircularProgressAnimation()
                .frame(maxWidth: 300)
            Text(
                viewModel.loadingState == .generating
                ? Loc.Quizzes.Loading.generatingPronunciationSentences
                : Loc.Quizzes.Loading.preparingPronunciation
            )
            .font(.subheadline)
            .foregroundStyle(.secondary)
            Text(Loc.Quizzes.Loading.pronunciationDescription)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 16) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.red.gradient)

                Text(Loc.Quizzes.quizUnavailable)
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                Text(message)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .padding(.horizontal, 32)

            ActionButton(
                Loc.Quizzes.backToQuizzes,
                systemImage: "chevron.left",
                style: .borderedProminent
            ) {
                dismiss()
            }
            .padding(.horizontal, 32)

            Spacer()
        }
    }
}

