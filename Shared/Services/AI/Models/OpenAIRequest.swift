//
//  OpenAIRequest.swift
//  My Dictionary
//
//  Created by Alexander Riakhin on 8/19/25.
//

import Foundation
import OpenAI

// MARK: - User Profile Context

/// User profile context for AI requests to provide personalized responses
struct AIUserProfileContext: Codable {
    let userName: String
    let userType: String
    let ageGroup: String
    let learningGoals: [String]
    let studyLanguages: [String]
    let interests: [String]
    let weeklyWordGoal: Int
    let preferredStudyTime: String
    
    init(from profile: UserOnboardingProfile) {
        self.userName = profile.userName
        self.userType = profile.userType.rawValue
        self.ageGroup = profile.ageGroup.rawValue
        self.learningGoals = profile.learningGoals.map { $0.rawValue }
        self.studyLanguages = profile.studyLanguages.map { "\($0.language.rawValue) (\($0.proficiencyLevel.rawValue))" }
        self.interests = profile.interests.map { $0.rawValue }
        self.weeklyWordGoal = profile.weeklyWordGoal
        self.preferredStudyTime = profile.preferredStudyTime.rawValue
    }
}

// MARK: - JSON Response Models

struct AIWordDefinition: Codable, JSONSchemaConvertible {
    let partOfSpeech: PartOfSpeech
    let definition: String
    let examples: [String]
    
    static let example: Self = {
        .init(
            partOfSpeech: .noun,
            definition: "a building or room containing collections of books, periodicals, and sometimes films and recorded music for people to read, borrow, or refer to",
            examples: [
                "The university library has over a million books.",
                "I spent the afternoon studying in the library."
            ]
        )
    }()
}

struct AIWordResponse: Codable, JSONSchemaConvertible {
    let definitions: [AIWordDefinition]
    let pronunciation: String
    
    static let example: Self = {
        .init(
            definitions: [
                AIWordDefinition.example
            ],
            pronunciation: "/ˈlaɪbrəri/"
        )
    }()
}

struct AIRelatedWordWithDefinition: Codable {
    let word: String
    let definition: String
    let example: String
    let partOfSpeech: PartOfSpeech
}

// MARK: - AI Quiz Response Models

struct AISentenceEvaluation: Codable, JSONSchemaConvertible {
    let targetWord: String
    let sentence: String
    let usageScore: Int
    let grammarScore: Int
    let overallScore: Int
    let feedback: String
    let isCorrect: Bool
    let suggestions: [String]
    
    static let example: Self = {
        .init(
            targetWord: "library",
            sentence: "I went to the library to study for my exam.",
            usageScore: 9,
            grammarScore: 10,
            overallScore: 9,
            feedback: "Excellent usage of the word 'library' in a natural context.",
            isCorrect: true,
            suggestions: ["Consider using 'public library' for more specificity"]
        )
    }()
}

struct AISentenceEvaluations: Codable, JSONSchemaConvertible {
    let sentences: [AISentenceEvaluation]

    static let example: Self = {
        .init(sentences: [AISentenceEvaluation.example])
    }()
}

struct AIContextQuestion: Codable, JSONSchemaConvertible {
    let word: String
    let question: String
    let options: [AIContextOption]
    let correctOptionIndex: Int
    let explanation: String
    
    static let example: Self = {
        .init(
            word: "library",
            question: "Which sentence best uses the word 'library'?",
            options: [
                AIContextOption.example,
                AIContextOption(
                    text: "The library is a place where books are stored.",
                    isCorrect: false,
                    explanation: "This is a definition, not a usage example."
                )
            ],
            correctOptionIndex: 0,
            explanation: "The first option shows proper usage of 'library' in a natural sentence context."
        )
    }()
}

struct AIContextOption: Codable, JSONSchemaConvertible {
    let text: String
    let isCorrect: Bool
    let explanation: String
    
    static let example: Self = {
        .init(
            text: "I borrowed three books from the library yesterday.",
            isCorrect: true,
            explanation: "This sentence demonstrates proper usage of 'library' in a natural context."
        )
    }()
}

struct AIFillInTheBlankStory: Codable, JSONSchemaConvertible {
    let word: String
    let story: String
    let options: [AIFillInTheBlankOption]
    let correctOptionIndex: Int
    let explanation: String

    init(
        word: String,
        story: String,
        options: [AIFillInTheBlankOption],
        correctOptionIndex: Int,
        explanation: String
    ) {
        self.word = word
        self.story = story
        self.options = options
        self.correctOptionIndex = correctOptionIndex
        self.explanation = explanation
    }
    
    static let example: Self = {
        .init(
            word: "library",
            story: "Sarah spent her afternoon at the _, reading books and studying for her upcoming exam.",
            options: [
                AIFillInTheBlankOption.example,
                AIFillInTheBlankOption(
                    text: "bookstore",
                    isCorrect: false,
                    explanation: "A bookstore is where you buy books, not borrow them."
                )
            ],
            correctOptionIndex: 0,
            explanation: "Library is the correct answer as it's a place where you can read and study, and typically borrow books."
        )
    }()
}

struct AIFillInTheBlankOption: Codable, JSONSchemaConvertible {
    let text: String
    let isCorrect: Bool
    let explanation: String
    
    static let example: Self = {
        .init(
            text: "library",
            isCorrect: true,
            explanation: "Library is the correct answer as it's a place where you can read and study."
        )
    }()
}

