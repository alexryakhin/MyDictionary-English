//
//  SpoonacularNetworkService.swift
//  PureBite
//
//  Created by Aleksandr Riakhin on 6/16/24.
//

import Foundation

protocol SpoonacularNetworkServiceInterface {
    nonisolated func searchRecipes(params: SearchRecipesParams) async throws -> RecipeSearchResponse
    nonisolated func searchIngredients(params: SearchIngredientsParams) async throws -> IngredientSearchResponse
    nonisolated func recipeInformation(id: Int) async throws -> Recipe
    nonisolated func ingredientInformation(params: IngredientInformationParams) async throws -> IngredientFull
}

final class SpoonacularNetworkService: SpoonacularNetworkServiceInterface {
    private let networkService: NetworkServiceInterface
    private let apiKeyManager: SpoonacularAPIKeyManagerInterface

    init(
        networkService: NetworkServiceInterface,
        apiKeyManager: SpoonacularAPIKeyManagerInterface
    ) {
        self.networkService = networkService
        self.apiKeyManager = apiKeyManager
    }

    func searchRecipes(params: SearchRecipesParams) async throws -> RecipeSearchResponse {
        let endpoint = SpoonacularAPIEndpoint.searchRecipes(params: params)
        return try await networkService.request(for: endpoint, apiKey: getAPIKey(), errorType: SpoonacularServerError.self)
    }

    func searchIngredients(params: SearchIngredientsParams) async throws -> IngredientSearchResponse {
        let endpoint = SpoonacularAPIEndpoint.searchIngredients(params: params)
        return try await networkService.request(for: endpoint, apiKey: getAPIKey(), errorType: SpoonacularServerError.self)
    }

    func recipeInformation(id: Int) async throws -> Recipe {
        let endpoint = SpoonacularAPIEndpoint.recipeInformation(id: id)
        return try await networkService.request(for: endpoint, apiKey: getAPIKey(), errorType: SpoonacularServerError.self)
    }

    nonisolated func ingredientInformation(params: IngredientInformationParams) async throws -> IngredientFull {
        let endpoint = SpoonacularAPIEndpoint.ingredientInformation(params: params)
        return try await networkService.request(for: endpoint, apiKey: getAPIKey(), errorType: SpoonacularServerError.self)
    }

    private func getAPIKey() throws -> String {
        guard let apiKey = apiKeyManager.getCurrentAPIKey() else {
            throw CoreError.networkError(.missingAPIKey)
        }
        return apiKey
    }
}

#if DEBUG
class SpoonacularNetworkServiceMock: SpoonacularNetworkServiceInterface {
    let networkService = NetworkServiceMock()
    let apiKeyManager = SpoonacularAPIKeyManager(apiKeys: ["MOCK_API_KEY"])

    init() {}
    func searchRecipes(params: SearchRecipesParams) async throws -> RecipeSearchResponse {
        let endpoint = SpoonacularAPIEndpoint.searchRecipes(params: params)
        return try await networkService.request(
            for: endpoint,
            apiKey: getAPIKey(),
            errorType: SpoonacularServerError.self
        )
    }

    nonisolated func searchIngredients(params: SearchIngredientsParams) async throws -> IngredientSearchResponse {
        let endpoint = SpoonacularAPIEndpoint.searchIngredients(params: params)
        return try await networkService.request(
            for: endpoint,
            apiKey: getAPIKey(),
            errorType: SpoonacularServerError.self
        )
    }

    func recipeInformation(id: Int) async throws -> Recipe {
        let endpoint = SpoonacularAPIEndpoint.recipeInformation(id: id)
        return try await networkService.request(
            for: endpoint,
            apiKey: getAPIKey(),
            errorType: SpoonacularServerError.self
        )
    }

    nonisolated func ingredientInformation(params: IngredientInformationParams) async throws -> IngredientFull {
        let endpoint = SpoonacularAPIEndpoint.ingredientInformation(params: params)
        return try await networkService.request(
            for: endpoint,
            apiKey: getAPIKey(),
            errorType: SpoonacularServerError.self
        )
    }

    private func getAPIKey() throws -> String {
        guard let apiKey = apiKeyManager.getCurrentAPIKey() else {
            throw CoreError.networkError(.missingAPIKey)
        }
        return apiKey
    }
}
#endif
