//
//  RandomRecipesParams.swift
//  PureBite
//
//  Created by Aleksandr Riakhin on 6/23/24.
//

import Foundation

struct RandomRecipesParams: SpoonacularAPIParams {

    // Whether to include nutritional information to returned recipes.
    let includeNutrition: Bool?

    // The tags (can be diets, meal types, cuisines, or intolerances) that the recipe must have.
    let includingDiet: [Diet]
    let includingType: MealType?
    let includingCuisines: [Cuisine]
    let includingIntolerances: [Intolerance]

    // The tags (can be diets, meal types, cuisines, or intolerances) that the recipe must NOT have.
    let excludingDiet: [Diet]
    let excludingType: MealType?
    let excludingCuisines: [Cuisine]
    let excludingIntolerances: [Intolerance]

    // The number of random recipes to be returned (between 1 and 100).
    let number: Int?

    func queryItems() -> [URLQueryItem] {
        var queryItems: [URLQueryItem] = []

        if let includeNutrition {
            queryItems.append(URLQueryItem(name: "includeNutrition", value: String(includeNutrition)))
        }

        var includeTags = [String]()
        if let includingType {
            includeTags.append(includingType.rawValue)
        }
        includeTags.append(contentsOf: includingDiet.map { $0.rawValue })
        includeTags.append(contentsOf: includingCuisines.map { $0.rawValue })
        includeTags.append(contentsOf: includingIntolerances.map { $0.rawValue })
        if !includeTags.isEmpty {
            queryItems.append(URLQueryItem(name: "include-tags", value: includeTags.joined(separator: ",")))
        }

        var excludeTags = [String]()
        if !excludeTags.isEmpty {
            queryItems.append(URLQueryItem(name: "exclude-tags", value: excludeTags.joined(separator: ",")))
        }
        if let number {
            queryItems.append(URLQueryItem(name: "number", value: String(number)))
        }

        return queryItems
    }
}
