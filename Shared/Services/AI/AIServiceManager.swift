//
//  AIService.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/9/25.
//

import Foundation
import Combine
import FirebaseAuth

// MARK: - AI Service Interface

protocol AIAPIServiceInterface {
    func generateWordInformation(
        for word: String,
        maxDefinitions: Int,
        inputLanguage: InputLanguage,
        userLanguage: String,
        userId: String
    ) async throws -> AIWordResponse
}

// MARK: - AI Service Manager Interface

protocol AIServiceInterface {
    func generateWordInformation(
        for word: String,
        maxDefinitions: Int,
        inputLanguage: InputLanguage
    ) async throws -> AIWordResponse
    
    /// Checks if the user can make an AI request
    func canMakeAIRequest() -> Bool
    
    /// Gets the remaining AI requests for today
    func getRemainingRequests() -> Int
    
    /// Gets the total daily limit
    func getDailyLimit() -> Int
}

// MARK: - AI Service Manager

final class AIService: AIServiceInterface {

    static let shared = AIService()

    private let apiService: AIAPIServiceInterface
    private let usageTracker = AIUsageTracker.shared

    private init() {
#if DEBUG
        self.apiService = OpenAIAPIService()
        print("🔧 [AIService] Using OpenAIAPIService for DEBUG mode")
#else
        self.apiService = FirebaseOpenAIProxy.shared
        print("🔧 [AIService] Using FirebaseOpenAIProxy for RELEASE mode")
#endif
    }

    func generateWordInformation(
        for word: String,
        maxDefinitions: Int = 10,
        inputLanguage: InputLanguage
    ) async throws -> AIWordResponse {
        do {
            // Check if user can make AI request
            guard usageTracker.canMakeAIRequest() else {
                throw DictionaryError.aiUsageLimitExceeded
            }
            
            guard let userId = Auth.auth().currentUser?.uid else {
                throw DictionaryError.userNotAuthenticated
            }

            let response = try await apiService.generateWordInformation(
                for: word,
                maxDefinitions: maxDefinitions,
                inputLanguage: inputLanguage,
                userLanguage: getCurrentAppLanguage(),
                userId: userId
            )
            
            // Record the usage after successful request
            usageTracker.recordAIUsage()
            
            return response
        } catch {
            throw error
        }
    }
    
    func canMakeAIRequest() -> Bool {
        return usageTracker.canMakeAIRequest()
    }
    
    func getRemainingRequests() -> Int {
        return usageTracker.getRemainingRequests()
    }
    
    func getDailyLimit() -> Int {
        return usageTracker.getDailyLimit()
    }

    private func getCurrentAppLanguage() -> String {
        let currentLanguageCode = Locale.current.language.languageCode?.identifier ?? "en"
        return Locale(identifier: "en_US").localizedString(forLanguageCode: currentLanguageCode) ?? "English"
    }
}

// MARK: - AI Response Extensions

extension AIWordResponse {
    func toWordDefinitions() -> [WordDefinition] {
        return definitions.map { aiDefinition in
            let partOfSpeech = PartOfSpeech(rawValue: aiDefinition.partOfSpeech.lowercased()) ?? .unknown
            return WordDefinition(
                partOfSpeech: partOfSpeech,
                text: aiDefinition.definition,
                examples: aiDefinition.examples
            )
        }
    }
}
