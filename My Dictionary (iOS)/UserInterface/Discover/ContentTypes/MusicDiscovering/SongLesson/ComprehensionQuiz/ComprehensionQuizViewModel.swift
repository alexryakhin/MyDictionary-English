import Foundation

extension SongLesson {
    final class ComprehensionQuizViewModel: ObservableObject {
        @Published private(set) var currentQuestionIndex: Int = 0
        @Published private(set) var answers: [Int: Int]
        @Published var showFeedback: Bool = false

        let items: [MCQItem]
        let questionIndexOffset: Int

        private let onAnswer: (QuizSubmission) -> Void
        private let onCompletion: ([QuizSubmission]) -> Void

        init(
            items: [MCQItem],
            initialAnswers: [Int: Int] = [:],
            questionIndexOffset: Int = 0,
            onAnswer: @escaping (QuizSubmission) -> Void,
            onCompletion: @escaping ([QuizSubmission]) -> Void
        ) {
            self.items = items
            self.answers = initialAnswers
            self.questionIndexOffset = questionIndexOffset
            self.onAnswer = onAnswer
            self.onCompletion = onCompletion

            showFeedback = initialAnswers[currentQuestionIndex] != nil
        }

        var currentItem: MCQItem? {
            guard items.indices.contains(currentQuestionIndex) else { return nil }
            return items[currentQuestionIndex]
        }

        var currentSelection: Int? {
            answers[currentQuestionIndex]
        }

        var currentSelectionIsCorrect: Bool? {
            guard
                let item = currentItem,
                let selection = currentSelection,
                item.options.indices.contains(selection)
            else { return nil }
            return item.options[selection] == item.correctAnswer
        }

        var currentExplanation: String? {
            currentItem?.explanation
        }

        var allQuestionsAnswered: Bool {
            items.indices.allSatisfy { answers[$0] != nil }
        }

        func selectOption(at optionIndex: Int) {
            guard let item = currentItem else { return }
            guard answers[currentQuestionIndex] == nil else { return }
            guard item.options.indices.contains(optionIndex) else { return }

            answers[currentQuestionIndex] = optionIndex
            showFeedback = true

            let isCorrect = item.options[optionIndex] == item.correctAnswer
            let submission = QuizSubmission(
                questionIndex: questionIndexOffset + currentQuestionIndex,
                selectedAnswerIndex: optionIndex,
                isCorrect: isCorrect,
                type: .meaningMCQ
            )
            onAnswer(submission)
        }

        func goToNextQuestion() {
            let nextIndex = currentQuestionIndex + 1
            guard items.indices.contains(nextIndex) else { return }
            currentQuestionIndex = nextIndex
            showFeedback = answers[currentQuestionIndex] != nil
        }

        func goToPreviousQuestion() {
            let previousIndex = currentQuestionIndex - 1
            guard items.indices.contains(previousIndex) else { return }
            currentQuestionIndex = previousIndex
            showFeedback = answers[currentQuestionIndex] != nil
        }

        func finishQuiz() {
            let submissions = items.enumerated().compactMap { index, item -> QuizSubmission? in
                guard let answerIndex = answers[index] else { return nil }
                let isCorrect = item.options.indices.contains(answerIndex) && item.options[answerIndex] == item.correctAnswer
                return QuizSubmission(
                    questionIndex: questionIndexOffset + index,
                    selectedAnswerIndex: answerIndex,
                    isCorrect: isCorrect,
                    type: .meaningMCQ
                )
            }
            onCompletion(submissions)
        }
    }
}
