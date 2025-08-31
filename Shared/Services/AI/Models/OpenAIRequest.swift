//
//  OpenAIRequest.swift
//  My Dictionary
//
//  Created by Alexander Riakhin on 8/19/25.
//

import Foundation

// MARK: - Firebase OpenAI Proxy Models

struct FirebaseOpenAIRequest: Codable {
    let word: String
    let maxDefinitions: Int
    let targetLanguage: String
    let userId: String
}

struct FirebaseOpenAIResponse: Codable {
    let success: Bool
    let data: String?
    let usage: UsageData?
    let error: String?

    struct UsageData: Codable {
        let promptTokens: Int
        let completionTokens: Int
        let totalTokens: Int
    }
}

// MARK: - OpenAI API Models

struct OpenAIRequest: Codable {
    let model: String
    let messages: [OpenAIMessage]
    let temperature: Double
    let maxTokens: Int

    enum CodingKeys: String, CodingKey {
        case model, messages, temperature
        case maxTokens = "max_tokens"
    }
}

struct OpenAIMessage: Codable {
    let role: String
    let content: String
}

struct OpenAIResponse: Codable {
    let choices: [OpenAIChoice]
    let usage: OpenAIUsage
}

struct OpenAIChoice: Codable {
    let message: OpenAIMessage
    let finishReason: String

    enum CodingKeys: String, CodingKey {
        case message
        case finishReason = "finish_reason"
    }
}

struct OpenAIUsage: Codable {
    let promptTokens: Int
    let completionTokens: Int
    let totalTokens: Int

    enum CodingKeys: String, CodingKey {
        case promptTokens = "prompt_tokens"
        case completionTokens = "completion_tokens"
        case totalTokens = "total_tokens"
    }
}

// MARK: - JSON Response Models

struct AIWordDefinition: Codable {
    let partOfSpeech: String
    let definition: String
    let examples: [String]
}

struct AIWordResponse: Codable {
    let definitions: [AIWordDefinition]
    let pronunciation: String
}

struct AIRelatedWordWithDefinition: Codable {
    let word: String
    let definition: String
    let example: String
    let partOfSpeech: String
}

// MARK: - OpenAI JSON Response
struct OpenAIWordResponse: Codable {
    let pronunciation: String
    let definitions: [AIWordDefinition]
}

struct OpenAIRelatedWordsResponse: Codable {
    let relatedWords: [OpenAIRelatedWordData]
}

struct OpenAIRelatedWordData: Codable {
    let word: String
    let definition: String
    let example: String
    let partOfSpeech: String
}

// MARK: - AI Quiz Response Models

struct AISentenceEvaluation: Codable {
    let targetWord: String
    let sentence: String
    let usageScore: Int
    let grammarScore: Int
    let overallScore: Int
    let feedback: String
    let isCorrect: Bool
    let suggestions: [String]
}

struct AIContextQuestion: Codable {
    let word: String
    let question: String
    let options: [AIContextOption]
    let correctOptionIndex: Int
    let explanation: String
}

struct AIContextOption: Codable {
    let text: String
    let isCorrect: Bool
    let explanation: String
}

struct AIFillInTheBlankStory: Codable {
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
}

struct AIFillInTheBlankOption: Codable {
    let text: String
    let isCorrect: Bool
    let explanation: String
}

// MARK: - OpenAI Quiz Response Models

struct OpenAISentenceEvaluationResponse: Codable {
    let targetWord: String
    let sentence: String
    let usageScore: Int
    let grammarScore: Int
    let overallScore: Int
    let feedback: String
    let isCorrect: Bool
    let suggestions: [String]
}

struct OpenAIContextQuestionResponse: Codable {
    let word: String
    let question: String
    let options: [OpenAIContextOptionData]
    let correctOptionIndex: Int
    let explanation: String
}

struct OpenAIContextOptionData: Codable {
    let text: String
    let isCorrect: Bool
    let explanation: String
}

struct OpenAIFillInTheBlankStoryResponse: Codable {
    let word: String
    let story: String
    let options: [OpenAIFillInTheBlankOptionData]
    let correctOptionIndex: Int
    let explanation: String
}

struct OpenAIFillInTheBlankOptionData: Codable {
    let text: String
    let isCorrect: Bool
    let explanation: String
}

// MARK: - Batch Response Models

struct OpenAISentencesEvaluationResponse: Codable {
    let evaluations: [OpenAISentenceEvaluationData]
}

struct OpenAISentenceEvaluationData: Codable {
    let targetWord: String
    let sentence: String
    let usageScore: Int
    let grammarScore: Int
    let overallScore: Int
    let feedback: String
    let isCorrect: Bool
    let suggestions: [String]
}

struct OpenAIContextQuestionsResponse: Codable {
    let questions: [OpenAIContextQuestionData]
}

struct OpenAIContextQuestionData: Codable {
    let word: String
    let question: String
    let options: [OpenAIContextOptionData]
    let correctOptionIndex: Int
    let explanation: String
}

struct OpenAIFillInTheBlankStoriesResponse: Codable {
    let stories: [OpenAIFillInTheBlankStoryData]
}

struct OpenAIFillInTheBlankStoryData: Codable {
    let word: String
    let story: String
    let options: [OpenAIFillInTheBlankOptionData]
    let correctOptionIndex: Int
    let explanation: String
}

// MARK: - Single Question Response Models

struct OpenAISingleContextQuestionResponse: Codable {
    let question: OpenAIContextQuestionData
}

struct OpenAISingleFillInTheBlankStoryResponse: Codable {
    let story: OpenAIFillInTheBlankStoryData
}
