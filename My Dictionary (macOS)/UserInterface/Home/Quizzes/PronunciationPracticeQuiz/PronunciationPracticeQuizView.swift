import SwiftUI

struct PronunciationPracticeQuizView: View {

    @StateObject private var viewModel: PronunciationPracticeQuizViewModel
    @Environment(\.dismiss) private var dismiss

    init(preset: QuizPreset) {
        _viewModel = StateObject(wrappedValue: PronunciationPracticeQuizViewModel(preset: preset))
    }

    var body: some View {
        Group {
            switch viewModel.loadingState {
            case .loading, .generating:
                loadingView
            case .error(let message):
                errorView(message: message)
            case .ready:
                if viewModel.isQuizComplete {
                    resultsView
                } else if let config = viewModel.quizConfig {
                    quizBody(config: config)
                } else {
                    loadingView
                }
            }
        }
        .groupedBackground()
        .navigationTitle(Loc.Quizzes.QuizTypes.pronunciationPractice)
        .toolbarTitleDisplayMode(.inlineLarge)
        .onDisappear {
            viewModel.handleDismissIfNeeded()
        }
        .onReceive(viewModel.dismissPublisher) {
            dismiss()
        }
    }

    private func quizBody(config: PronunciationQuizConfig) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                instructionsSection
                PronunciationQuizRecorderView(config: config)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .center)
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
                    currentDayStreak: viewModel.currentDayStreak
                )

                if !viewModel.wordSummaries.isEmpty {
                    summarySection
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .center)
        }
    }

    private var summarySection: some View {
        CustomSectionView(header: Loc.Quizzes.PronunciationPractice.reviewHeader, hPadding: .zero) {
            FormWithDivider(dividerLeadingPadding: .zero, dividerTrailingPadding: .zero) {
                ForEach(Array(viewModel.wordSummaries.enumerated()), id: \.element.id) { index, summary in
                    CellWrapper(
                        "\(index + 1). \(summary.word)",
                        mainContent: {
                            Text(summary.sentence)
                                .foregroundColor(.primary)
                                .fixedSize(horizontal: false, vertical: true)
                        },
                        trailingContent: {
                            if let isCorrect = summary.isCorrect {
                                Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .foregroundStyle(isCorrect ? Color.green : Color.red)
                            }
                        }
                    )
                    .alignmentGuide(.listRowSeparatorLeading) { $0[.leading] }
                }
            }
        }
    }

    private var instructionsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(Loc.Quizzes.PronunciationPractice.instructionsTitle)
                .font(.headline)

            Text(Loc.Quizzes.PronunciationPractice.instructionsDescription)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .clippedWithPaddingAndBackground()
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
            .font(.headline)
            .foregroundColor(.primary)
            Text(Loc.Quizzes.Loading.pronunciationDescription)
                .font(.subheadline)
                .foregroundColor(.secondary)
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
                    .foregroundColor(.secondary)
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

