//
//  AIServiceManager.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/9/25.
//

import Foundation
import Combine
import FirebaseAuth

// MARK: - AI Service Interface

protocol AIServiceInterface {
    func generateWordInformation(
        for word: String,
        maxDefinitions: Int,
        inputLanguage: InputLanguage,
        userLanguage: String,
        userId: String
    ) async throws -> AIWordResponse
}

// MARK: - AI Service Manager Interface

protocol AIServiceManagerInterface {
    func generateWordInformation(
        for word: String,
        maxDefinitions: Int,
        inputLanguage: InputLanguage
    ) async throws -> AIWordResponse
}

// MARK: - AI Service Manager

final class AIServiceManager: AIServiceManagerInterface {

    static let shared = AIServiceManager()

    private let aiService: AIServiceInterface

    private init() {
#if DEBUG
        self.aiService = OpenAIAPIService()
        print("🔧 [AIServiceManager] Using OpenAIAPIService for DEBUG mode")
#else
        self.aiService = FirebaseOpenAIProxy.shared
        print("🔧 [AIServiceManager] Using FirebaseOpenAIProxy for RELEASE mode")
#endif
    }

    func generateWordInformation(
        for word: String,
        maxDefinitions: Int = 10,
        inputLanguage: InputLanguage
    ) async throws -> AIWordResponse {
        do {
            guard let userId = Auth.auth().currentUser?.uid else {
                throw DictionaryError.userNotAuthenticated
            }

            return try await aiService.generateWordInformation(
                for: word,
                maxDefinitions: maxDefinitions,
                inputLanguage: inputLanguage,
                userLanguage: getCurrentAppLanguage(),
                userId: userId
            )
        } catch {
            throw error
        }
    }

    private func getCurrentAppLanguage() -> String {
        let currentLanguageCode = Locale.current.language.languageCode?.identifier ?? "en"
        return Locale(identifier: "en_US").localizedString(forLanguageCode: currentLanguageCode) ?? "English"
    }
}
