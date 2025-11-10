import Foundation

enum SongLesson {
    enum QuizQuestionType: String, Codable, Equatable, Hashable {
        case fillInBlank
        case meaningMCQ
    }

    struct QuizSubmission: Equatable {
        let questionIndex: Int
        let selectedAnswerIndex: Int
        let isCorrect: Bool
        let type: QuizQuestionType
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

extension SongLesson.QuizQuestionType {
    var sessionQuizType: MusicDiscoveringSession.QuizAnswer.QuizType {
        switch self {
        case .fillInBlank:
            return .fillInBlank
        case .meaningMCQ:
            return .meaningMCQ
        }
    }
}
