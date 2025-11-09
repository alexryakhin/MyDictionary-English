import Foundation

enum SongLesson {
    struct QuizSubmission: Equatable {
        let questionIndex: Int
        let selectedAnswerIndex: Int
        let isCorrect: Bool
    }

    struct ComprehensionQuizConfig {
        let items: [MCQItem]
        let initialAnswers: [Int: Int]
        let questionIndexOffset: Int
        let onAnswer: (QuizSubmission) -> Void
        let onCompletion: ([QuizSubmission]) -> Void
    }

    struct FillInBlankQuizConfig {
        let items: [FillInBlankItem]
        let initialAnswers: [Int: Int]
        let questionIndexOffset: Int
        let onAnswer: (QuizSubmission) -> Void
        let onCompletion: ([QuizSubmission]) -> Void
    }
}
