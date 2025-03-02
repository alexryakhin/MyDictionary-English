//
//  SpoonacularAPIEndpoint.swift
//  PureBite
//
//  Created by Aleksandr Riakhin on 6/16/24.
//

import Foundation

enum SpoonacularAPIEndpoint: APIEndpoint {
    case searchRecipes(params: SearchRecipesParams)
    case recipeInformation(id: Int)
    case getSimilarRecipes(id: Int)
    case getRandomRecipes
    case searchIngredients(params: SearchIngredientsParams)
    case ingredientInformation(params: IngredientInformationParams)

    func url(apiKey: String) -> URL? {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.spoonacular.com"
        components.queryItems = [
            URLQueryItem(name: "apiKey", value: apiKey)
        ]

        switch self {
        case .searchRecipes(let params):
            components.path = "/recipes/complexSearch"
            components.queryItems?.append(contentsOf: params.queryItems())
        case .recipeInformation(let id):
            components.path = "/recipes/\(id)/information"
            components.queryItems?.append(contentsOf: [
                URLQueryItem(name: "includeNutrition", value: "true"),
                URLQueryItem(name: "addTasteData", value: "true")
            ])
        case .getSimilarRecipes(let id):
            components.path = "/recipes/\(id)/similar"
        case .getRandomRecipes:
            components.path = "/recipes/random"
        case .searchIngredients(let params):
            components.path = "/food/ingredients/search"
            components.queryItems?.append(contentsOf: params.queryItems())
        case .ingredientInformation(let params):
            components.path = "/food/ingredients/\(params.id)/information"
            components.queryItems?.append(contentsOf: params.queryItems())
        }

        return components.url
    }

#if DEBUG
    var mockFileName: String {
        switch self {
        case .searchRecipes:
            return "searchRecipes"
        case .recipeInformation:
            return "recipeInformation"
        case .getSimilarRecipes:
            return "getSimilarRecipes"
        case .getRandomRecipes:
            return "getRandomRecipes"
        case .searchIngredients:
            return "searchIngredients"
        case .ingredientInformation:
            return "ingredientInformation"
        }
    }
    #endif
}
