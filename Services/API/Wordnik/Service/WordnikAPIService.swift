//
//  WordnikAPIService.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 2/24/25.
//

import Foundation

protocol WordnikAPIServiceInterface {
    /// Return definitions for a word
    func getDefinitions(
        for word: String,
        params: DefinitionsQueryParams?
    ) async throws -> [WordDefinition]

    /// Return a pronunciation for a word
    func getPronunciation(
        for word: String,
        params: PronunciationsQueryParams?
    ) async throws -> String
}

// MARK: - WordnikAPIService

final class WordnikAPIService: BaseAPIService, WordnikAPIServiceInterface {

    override var baseURL: String { "https://api.wordnik.com/v4" }
    override var apiKey: String { GlobalConstant.wordnikAPIKey }

    func getDefinitions(
        for word: String,
        params: DefinitionsQueryParams?
    ) async throws -> [WordDefinition] {
        let response: [WordDefinitionDTO] = try await fetchData(
            from: WordnikAPIPath.definitions(
                word: word,
                params: params
            ),
            customParams: [.apiKey]
        )
        return response.compactMap {
            guard let partOfSpeech = $0.partOfSpeech?.coreValue, let text = $0.text?.removingHTMLTags() else { return nil }
            return .init(
                partOfSpeech: partOfSpeech,
                text: text,
                examples: ($0.exampleUses ?? []).map { $0.text.removingHTMLTags() }
            )
        }
    }

    func getPronunciation(
        for word: String,
        params: PronunciationsQueryParams?
    ) async throws -> String {
        let pronunciations: [WordPronunciation] = try await fetchData(
            from: WordnikAPIPath.pronunciations(
                word: word,
                params: params
            ),
            customParams: [.apiKey]
        )

        if let ipa = pronunciations.first(where: { pronunciation in
            pronunciation.rawType == "IPA"
        }) {
            return ipa.raw
        } else if let first = pronunciations.first {
            return first.raw
        } else {
            throw CoreError.networkError(.noData)
        }
    }
}
