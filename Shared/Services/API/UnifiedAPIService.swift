//
//  UnifiedAPIService.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/9/25.
//

import Foundation

protocol UnifiedAPIServiceInterface {
    /// Return definitions for a word from a randomly selected API
    func getDefinitions(
        for word: String,
        params: DefinitionsQueryParams?
    ) async throws -> [WordDefinition]

    /// Return a pronunciation for a word from a randomly selected API
    func getPronunciation(
        for word: String,
        params: PronunciationsQueryParams?
    ) async throws -> String
}

// MARK: - UnifiedAPIService

final class UnifiedAPIService: UnifiedAPIServiceInterface {

    static let shared = UnifiedAPIService()

    private let wordnikService: WordnikAPIServiceInterface
    private let dictionaryAPIService: DictionaryAPIServiceInterface

    private init(
        wordnikService: WordnikAPIServiceInterface = WordnikAPIService.shared,
        dictionaryAPIService: DictionaryAPIServiceInterface = DictionaryAPIService.shared
    ) {
        self.wordnikService = wordnikService
        self.dictionaryAPIService = dictionaryAPIService
    }

    func getDefinitions(
        for word: String,
        params: DefinitionsQueryParams?
    ) async throws -> [WordDefinition] {
        let useWordnik = Bool.random()
        
        do {
            if useWordnik {
                AnalyticsService.shared.logEvent(.wordnikAPISelected)
                return try await wordnikService.getDefinitions(for: word, params: params)
            } else {
                AnalyticsService.shared.logEvent(.dictionaryAPISelected)
                return try await dictionaryAPIService.getDefinitions(for: word)
            }
        } catch {
            // If the first API fails, try the other one
            if useWordnik {
                AnalyticsService.shared.logEvent(.wordnikAPIFailed)
                return try await dictionaryAPIService.getDefinitions(for: word)
            } else {
                AnalyticsService.shared.logEvent(.dictionaryAPIFailed)
                return try await wordnikService.getDefinitions(for: word, params: params)
            }
        }
    }

    func getPronunciation(
        for word: String,
        params: PronunciationsQueryParams?
    ) async throws -> String {
        let useWordnik = Bool.random()
        
        do {
            if useWordnik {
                AnalyticsService.shared.logEvent(.wordnikAPISelected)
                return try await wordnikService.getPronunciation(for: word, params: params)
            } else {
                AnalyticsService.shared.logEvent(.dictionaryAPISelected)
                return try await dictionaryAPIService.getPronunciation(for: word)
            }
        } catch {
            // If the first API fails, try the other one
            if useWordnik {
                AnalyticsService.shared.logEvent(.wordnikAPIFailed)
                return try await dictionaryAPIService.getPronunciation(for: word)
            } else {
                AnalyticsService.shared.logEvent(.dictionaryAPIFailed)
                return try await wordnikService.getPronunciation(for: word, params: params)
            }
        }
    }
}
