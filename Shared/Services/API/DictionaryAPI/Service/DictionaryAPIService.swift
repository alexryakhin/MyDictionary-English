//
//  DictionaryAPIService.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/9/25.
//

import Foundation

protocol DictionaryAPIServiceInterface {
    /// Return definitions for a word
    func getDefinitions(
        for word: String
    ) async throws -> [WordDefinition]

    /// Return a pronunciation for a word
    func getPronunciation(
        for word: String
    ) async throws -> String
}

// MARK: - DictionaryAPIService

final class DictionaryAPIService: BaseAPIService, DictionaryAPIServiceInterface {

    static let shared = DictionaryAPIService()

    override var baseURL: String { "https://api.dictionaryapi.dev/api/v2/entries/en" }
    override var apiKey: String { "" } // DictionaryAPI.dev doesn't require an API key

    private override init() {}

    func getDefinitions(
        for word: String
    ) async throws -> [WordDefinition] {
        let url = try buildURL(for: DictionaryAPIPath.definitions(word: word), customParams: [])
        print("🔍 [DictionaryAPIService] Requesting URL: \(url)")
        
        do {
            let response: [DictionaryAPI.Response] = try await fetchData(
                from: DictionaryAPIPath.definitions(word: word),
                customParams: []
            )
            
            return response.flatMap { entry in
                entry.meanings.compactMap { meaning in
                    guard let partOfSpeech = PartOfSpeech(rawValue: meaning.partOfSpeech) else { return nil }
                    
                    return WordDefinition(
                        partOfSpeech: partOfSpeech,
                        text: meaning.definitions.first?.definition ?? "",
                        examples: meaning.definitions.compactMap { $0.example }
                    )
                }
            }
        } catch {
            print("❌ [DictionaryAPIService] Error fetching definitions for '\(word)': \(error)")
            throw error
        }
    }

    func getPronunciation(
        for word: String
    ) async throws -> String {
        let url = try buildURL(for: DictionaryAPIPath.definitions(word: word), customParams: [])
        print("🔍 [DictionaryAPIService] Requesting pronunciation URL: \(url)")
        
        do {
            let response: [DictionaryAPI.Response] = try await fetchData(
                from: DictionaryAPIPath.definitions(word: word),
                customParams: []
            )
            
            guard let firstEntry = response.first else {
                throw CoreError.networkError(.noData)
            }
            
            // Find the first phonetic with text
            if let phoneticWithText = firstEntry.phonetics.first(where: { $0.text != nil && !$0.text!.isEmpty }) {
                return phoneticWithText.text!
            }
            
            // If no phonetic with text, throw an error
            throw CoreError.networkError(.noData)
        } catch {
            print("❌ [DictionaryAPIService] Error fetching pronunciation for '\(word)': \(error)")
            throw error
        }
    }
}
