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
