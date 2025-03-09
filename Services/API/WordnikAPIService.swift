//
//  WordnikAPIService.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 2/24/25.
//

import Foundation
import Shared
import Core

public protocol WordnikAPIServiceInterface {
    /// Return definitions for a word
    func getDefinitions(
        for word: String,
        params: DefinitionsQueryParams?
    ) async throws -> [Core.WordDefinition]

    /// Return a pronunciation for a word
    func getPronunciation(
        for word: String,
        params: PronunciationsQueryParams?
    ) async throws -> String
}

// MARK: - WordnikAPIService

public final class WordnikAPIService: BaseAPIService, WordnikAPIServiceInterface {

    override public var baseURL: String { "https://api.wordnik.com/v4" }
    override public var apiKey: String { GlobalConstant.wordnikAPIKey }

    public func getDefinitions(
        for word: String,
        params: DefinitionsQueryParams?
    ) async throws -> [Core.WordDefinition] {
        let response: [WordDefinition] = try await fetchData(
            from: WordnikAPIPath.definitions(
                word: word,
                params: params
            ),
            customParams: [.apiKey]
        )
        return response.map {
            .init(
                partOfSpeech: $0.partOfSpeech,
                text: $0.text,
                examples: ($0.exampleUses ?? []).map(\.text)
            )
        }
    }

    public func getPronunciation(
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

        if let first = pronunciations.first(where: { pronunciation in
            pronunciation.rawType == "IPA"
        }) {
            return first.raw
        } else {
            throw CoreError.networkError(.noData)
        }
    }
}
