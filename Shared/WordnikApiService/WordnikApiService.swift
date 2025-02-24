//
//  WordnikApiService.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 2/24/25.
//

import Foundation

protocol WordnikApiServiceInterface {
    /// Return definitions for a word
    func getDefinitions(
        for word: String,
        params: DefinitionsQueryParams?
    ) async throws -> [WordDefinition]
}

// MARK: - WordnikApiService

final class WordnikApiService: BaseApiService, WordnikApiServiceInterface {

    override var baseURL: String { "https://api.wordnik.com/v4" }
    override var apiKey: String { GlobalConstant.wordnikApiKey }

    func getDefinitions(
        for word: String,
        params: DefinitionsQueryParams?
    ) async throws -> [WordDefinition] {
        try await fetchData(
            from: WordnikApiPath.definitions(
                word: word,
                params: params
            ),
            customParams: [.apiKey]
        )
    }
}
