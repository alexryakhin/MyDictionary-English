import SwiftUI

extension SongLesson {
    struct FillInBlankQuizView: View {
        private let config: FillInBlankQuizConfig

        @StateObject private var viewModel: FillInBlankQuizViewModel

        init(config: FillInBlankQuizConfig) {
            self.config = config
            _viewModel = StateObject(
                wrappedValue: FillInBlankQuizViewModel(
                    items: config.items,
                    initialAnswers: config.initialAnswers,
                    questionIndexOffset: config.questionIndexOffset,
                    onAnswer: config.onAnswer,
                    onCompletion: config.onCompletion
                )
            )
        }

        var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                ProgressView(
                    value: Double(viewModel.currentQuestionIndex + 1),
                    total: Double(max(viewModel.items.count, 1))
                )
                .progressViewStyle(.linear)

                Text(Loc.MusicDiscovering.Quiz.Common.questionProgress(viewModel.currentQuestionIndex + 1, viewModel.items.count))
                    .font(.caption)
                    .foregroundColor(.secondary)

                if let item = viewModel.currentItem {
                    quizCard(for: item)
                }

                questionNavigation()
            }
        }

        private func quizCard(for item: FillInBlankItem) -> some View {
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(Loc.MusicDiscovering.Quiz.FillBlank.prompt)
                        .font(.subheadline)
                        .foregroundColor(.primary)

                    Text(item.lyricReference.replacingOccurrences(of: item.blankWord, with: "___"))
                        .font(.headline)
                        .foregroundColor(.primary)
                }

                ForEach(Array(item.options.enumerated()), id: \.offset) { optionIndex, option in
                    optionButton(
                        text: option,
                        optionIndex: optionIndex,
                        isCorrectAnswer: option == item.blankWord
                    )
                }

                if viewModel.showFeedback, let isCorrect = viewModel.currentSelectionIsCorrect {
                    feedbackView(isCorrect: isCorrect)
                }
            }
            .clippedWithPaddingAndBackground(.tertiarySystemGroupedBackground, in: .rect(cornerRadius: 12))
        }

        private func optionButton(text: String, optionIndex: Int, isCorrectAnswer: Bool) -> some View {
            let isSelected = viewModel.currentSelection == optionIndex
            let isQuestionAnswered = viewModel.currentSelection != nil

            return Button {
                let wasAnswered = viewModel.currentSelection != nil
                viewModel.selectOption(at: optionIndex)
                if !wasAnswered, let isCorrect = viewModel.currentSelectionIsCorrect {
                    HapticManager.shared.triggerImpact(style: isCorrect ? .medium : .light)
                }
                if viewModel.currentQuestionIndex == viewModel.items.count - 1 {
                    viewModel.finishQuiz()
                }
            } label: {
                HStack {
                    Text(text)
                        .font(.body)
                        .multilineTextAlignment(.leading)
                        .foregroundColor(isSelected ? .white : .primary)

                    Spacer()

                    if isSelected {
                        Image(systemName: isCorrectAnswer ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(.white)
                    }
                }
                .padding()
                .background(
                    isSelected
                        ? (isCorrectAnswer ? Color.green : Color.red)
                        : Color.secondarySystemGroupedBackground
                )
                .cornerRadius(8)
            }
            .buttonStyle(.plain)
            .disabled(isQuestionAnswered)
        }

        private func feedbackView(isCorrect: Bool) -> some View {
            HStack(spacing: 8) {
                Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(isCorrect ? .green : .red)

                Text(isCorrect ? Loc.MusicDiscovering.Quiz.FillBlank.Feedback.correct : Loc.MusicDiscovering.Quiz.FillBlank.Feedback.incorrect)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(isCorrect ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
            .cornerRadius(8)
        }

        private func questionNavigation() -> some View {
            HStack {
                ActionButton(
                    Loc.MusicDiscovering.Quiz.Navigation.previous,
                    systemImage: "chevron.left"
                ) {
                    viewModel.goToPreviousQuestion()
                }
                .disabled(viewModel.currentQuestionIndex == 0)

                ActionButton(
                    Loc.MusicDiscovering.Quiz.Navigation.next,
                    systemImage: "chevron.right"
                ) {
                    viewModel.goToNextQuestion()
                }
                .disabled(viewModel.currentQuestionIndex == viewModel.items.count - 1)
            }
        }
    }
}

