//
//  Ingredient.swift
//  PureBite
//
//  Created by Aleksandr Riakhin on 6/23/24.
//

import Foundation

struct IngredientFull: Codable, Identifiable, Equatable, Hashable {
    let id: Int
    let original: String
    let originalName: String
    let name: String
    let amount: Double
    let unit: String
    let unitShort: String
    let unitLong: String
    let possibleUnits: [String]
    let estimatedCost: EstimatedCost
    let consistency: String
    let shoppingListUnits: [String]?
    let aisle: String
    let image: String?
    let meta: [String]
    let nutrition: Nutrition
    let categoryPath: [String]

    var imageURL: URL? {
        guard let image else { return nil }
        return URL(string: "https://img.spoonacular.com/ingredients_500x500/\(image)")
    }

    // Nested structures
    struct EstimatedCost: Codable, Hashable {
        let value: Double
        let unit: String
    }

    struct Nutrition: Codable, Hashable {
        let nutrients: [Nutrient]
        let properties: [Property]
        let flavonoids: [Flavonoid]
        let caloricBreakdown: CaloricBreakdown
        let weightPerServing: WeightPerServing

        struct Nutrient: Codable, Hashable {
            let name: String
            let amount: Double
            let unit: String
            let percentOfDailyNeeds: Double
        }

        struct Property: Codable, Hashable {
            let name: String
            let amount: Double
            let unit: String
        }

        struct Flavonoid: Codable, Hashable {
            let name: String
            let amount: Double
            let unit: String
        }

        struct CaloricBreakdown: Codable, Hashable {
            let percentProtein: Double
            let percentFat: Double
            let percentCarbs: Double
        }

        struct WeightPerServing: Codable, Hashable {
            let amount: Double
            let unit: String
        }
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
        && lhs.name == rhs.name
        && lhs.image == rhs.image
    }
}
