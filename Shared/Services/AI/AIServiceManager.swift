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
    
    func evaluateSentences(
        sentences: [(sentence: String, targetWord: String)],
        userId: String,
        userLanguage: String
    ) async throws -> [AISentenceEvaluation]
    
    func generateSingleContextQuestion(
        word: String,
        wordLanguage: String,
        userId: String,
        userLanguage: String
    ) async throws -> AIContextQuestion
    
    func generateSingleFillInTheBlankStory(
        word: String,
        wordLanguage: String,
        userId: String,
        userLanguage: String
    ) async throws -> AIFillInTheBlankStory
}

// MARK: - AI Service Manager Interface

protocol AIServiceInterface {
    func generateWordInformation(
        for word: String,
        maxDefinitions: Int,
        inputLanguage: InputLanguage
    ) async throws -> AIWordResponse
    
    func evaluateSentences(
        sentences: [(sentence: String, targetWord: String)]
    ) async throws -> [AISentenceEvaluation]

    func generateSingleContextQuestion(
        word: String,
        wordLanguage: String
    ) async throws -> AIContextQuestion
    
    func generateSingleFillInTheBlankStory(
        word: String,
        wordLanguage: String
    ) async throws -> AIFillInTheBlankStory
    
    /// Checks if the user can make an AI request
    func canMakeAIRequest() -> Bool
    
    /// Gets the remaining AI requests for today
    func getRemainingRequests() -> Int
    
    /// Gets the total daily limit
    func getDailyLimit() -> Int
    
    // MARK: - Quiz Usage Tracking
    
    /// Checks if the user can run a specific AI quiz today
    func canRunQuizToday(_ quizType: Quiz) -> Bool
    
    /// Checks if a specific quiz type uses AI
    func isAIQuiz(_ quizType: Quiz) -> Bool
    
    /// Gets all AI quiz types
    func getAIQuizzes() -> [Quiz]
}

// MARK: - AI Service Manager

final class AIService: AIServiceInterface {

    static let shared = AIService()

    private let apiService: AIAPIServiceInterface
    private let usageTracker = AIUsageTracker.shared
    private let quizUsageTracker = QuizUsageTracker.shared
    private let reachabilityService = ReachabilityService.shared

    private init() {
#if DEBUG
        self.apiService = OpenAIAPIService()
        print("🔧 [AIService] Using OpenAIAPIService for DEBUG mode")
#else
        self.apiService = FirebaseOpenAIProxy()
        print("🔧 [AIService] Using FirebaseOpenAIProxy for RELEASE mode")
#endif
    }

    func generateWordInformation(
        for word: String,
        maxDefinitions: Int = 10,
        inputLanguage: InputLanguage
    ) async throws -> AIWordResponse {
        guard reachabilityService.isOffline == false else {
            throw DictionaryError.networkError
        }
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
    
    func evaluateSentences(
        sentences: [(sentence: String, targetWord: String)]
    ) async throws -> [AISentenceEvaluation] {
        guard reachabilityService.isOffline == false else {
            throw DictionaryError.networkError
        }

        do {
            // Check if user can make AI request
            guard usageTracker.canMakeAIRequest() else {
                throw DictionaryError.aiUsageLimitExceeded
            }
            
            guard let userId = Auth.auth().currentUser?.uid else {
                throw DictionaryError.userNotAuthenticated
            }

            let response = try await apiService.evaluateSentences(
                sentences: sentences,
                userId: userId,
                userLanguage: getCurrentAppLanguage()
            )

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
    
    // MARK: - Quiz Usage Tracking
    
    /// Checks if the user can run a specific AI quiz today
    /// - Parameter quizType: The type of quiz to check
    /// - Returns: true if user can run the quiz today, false otherwise
    func canRunQuizToday(_ quizType: Quiz) -> Bool {
        return (try? quizUsageTracker.canRunQuizToday(quizType)) ?? false
    }

    /// Checks if a specific quiz type uses AI
    /// - Parameter quizType: The quiz type to check
    /// - Returns: true if the quiz uses AI, false otherwise
    func isAIQuiz(_ quizType: Quiz) -> Bool {
        return quizUsageTracker.isAIQuiz(quizType)
    }
    
    /// Gets all AI quiz types
    /// - Returns: Array of AI-powered quiz types
    func getAIQuizzes() -> [Quiz] {
        return quizUsageTracker.getAIQuizzes()
    }

    private func getCurrentAppLanguage() -> String {
        let currentLanguageCode = Locale.current.language.languageCode?.identifier ?? "en"
        return Locale(identifier: "en_US").localizedString(forLanguageCode: currentLanguageCode) ?? "English"
    }
    
    func generateSingleContextQuestion(
        word: String,
        wordLanguage: String
    ) async throws -> AIContextQuestion {
        guard reachabilityService.isOffline == false else {
            throw DictionaryError.networkError
        }

        do {
            // Check if user can make AI request
            guard usageTracker.canMakeAIRequest() else {
                throw DictionaryError.aiUsageLimitExceeded
            }
            
            guard let userId = Auth.auth().currentUser?.uid else {
                throw DictionaryError.userNotAuthenticated
            }

            let response = try await apiService.generateSingleContextQuestion(
                word: word,
                wordLanguage: wordLanguage,
                userId: userId,
                userLanguage: getCurrentAppLanguage()
            )

            return response
        } catch {
            throw error
        }
    }
    
    func generateSingleFillInTheBlankStory(
        word: String,
        wordLanguage: String
    ) async throws -> AIFillInTheBlankStory {
        guard reachabilityService.isOffline == false else {
            throw DictionaryError.networkError
        }

        do {
            // Check if user can make AI request
            guard usageTracker.canMakeAIRequest() else {
                throw DictionaryError.aiUsageLimitExceeded
            }
            
            guard let userId = Auth.auth().currentUser?.uid else {
                throw DictionaryError.userNotAuthenticated
            }

            let response = try await apiService.generateSingleFillInTheBlankStory(
                word: word,
                wordLanguage: wordLanguage,
                userId: userId,
                userLanguage: getCurrentAppLanguage()
            )

            return response
        } catch {
            throw error
        }
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
