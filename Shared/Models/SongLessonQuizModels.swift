import Foundation

enum SongLesson {
    enum QuizQuestionType: String, Codable, Equatable, Hashable {
        case fillInBlank
        case meaningMCQ
        case pronunciation
    }

    struct QuizSubmission: Equatable {
        let questionIndex: Int
        let selectedAnswerIndex: Int
        let isCorrect: Bool
        let type: QuizQuestionType
        let spokenText: String?

        init(
            questionIndex: Int,
            selectedAnswerIndex: Int,
            isCorrect: Bool,
            type: QuizQuestionType,
            spokenText: String? = nil
        ) {
            self.questionIndex = questionIndex
            self.selectedAnswerIndex = selectedAnswerIndex
            self.isCorrect = isCorrect
            self.type = type
            self.spokenText = spokenText
        }
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

    struct SpeechQuizConfig {
        let items: [SpeechQuizItem]
        let initialAnswers: [Int: Int]
        let questionIndexOffset: Int
        let localeIdentifier: String
        let initialTranscripts: [Int: String]
        let onAnswer: (QuizSubmission) -> Void
        let onCompletion: ([QuizSubmission]) -> Void
    }

    struct SpeechQuizItem: Hashable {
        let lineNumber: Int
        let lyricLine: String
        let explanation: String
    }
}

extension SongLesson.QuizQuestionType {
    var sessionQuizType: MusicDiscoveringSession.QuizAnswer.QuizType {
        switch self {
        case .fillInBlank:
            return .fillInBlank
        case .meaningMCQ:
            return .meaningMCQ
        case .pronunciation:
            return .pronunciation
        }
    }
}
