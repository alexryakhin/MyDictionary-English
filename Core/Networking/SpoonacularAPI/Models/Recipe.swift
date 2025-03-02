//
//  Recipe.swift
//  PureBite
//
//  Created by Aleksandr Riakhin on 6/16/24.
//

import Foundation

// MARK: - Recipe
struct Recipe: Codable, Identifiable, Equatable, Hashable {
    let id: Int
    let title: String
    let aggregateLikes: Int?
    let analyzedInstructions: [AnalyzedInstruction]?
    let cheap: Bool?
    let cookingMinutes: Int?
    let creditsText: String?
    let cuisines: [String]?
    let dairyFree: Bool?
    let diets, dishTypes: [String]?
    let extendedIngredients: [ExtendedIngredient]?
    let gaps: String?
    let glutenFree: Bool?
    let healthScore: Int?
    let image: URL?
    let imageType, instructions: String?
    let lowFodmap: Bool?
    let nutrition: Nutrition?
    let occasions: [String]?
    let originalID: String?
    let preparationMinutes: Int?
    let pricePerServing: Double?
    let readyInMinutes, servings: Int?
    let sourceName: String?
    let sourceURL: String?
    let spoonacularScore: Double?
    let spoonacularSourceURL: String?
    let summary: String?
    let sustainable: Bool?
    let taste: Taste?
    let vegan, vegetarian, veryHealthy, veryPopular: Bool?
    let weightWatcherSmartPoints: Int?
    let isFavorite: Bool?

    enum CodingKeys: String, CodingKey {
        case aggregateLikes, analyzedInstructions, cheap, cookingMinutes, creditsText, cuisines, dairyFree, diets, dishTypes, extendedIngredients, gaps, glutenFree, healthScore, id, image, imageType, instructions, lowFodmap, nutrition, occasions
        case originalID = "originalId"
        case preparationMinutes, pricePerServing, readyInMinutes, servings, sourceName
        case sourceURL = "sourceUrl"
        case spoonacularScore
        case spoonacularSourceURL = "spoonacularSourceUrl"
        case summary, sustainable, taste, title, vegan, vegetarian, veryHealthy, veryPopular, weightWatcherSmartPoints
        case isFavorite
    }

    init(
        id: Int,
        title: String,
        aggregateLikes: Int? = nil,
        analyzedInstructions: [AnalyzedInstruction]? = nil,
        cheap: Bool? = nil,
        cookingMinutes: Int? = nil,
        creditsText: String? = nil,
        cuisines: [String]? = nil,
        dairyFree: Bool? = nil,
        diets: [String]? = nil,
        dishTypes: [String]? = nil,
        extendedIngredients: [ExtendedIngredient]? = nil,
        gaps: String? = nil,
        glutenFree: Bool? = nil,
        healthScore: Int? = nil,
        image: URL? = nil,
        imageType: String? = nil,
        instructions: String? = nil,
        lowFodmap: Bool? = nil,
        nutrition: Nutrition? = nil,
        occasions: [String]? = nil,
        originalID: String? = nil,
        preparationMinutes: Int? = nil,
        pricePerServing: Double? = nil,
        readyInMinutes: Int? = nil,
        servings: Int? = nil,
        sourceName: String? = nil,
        sourceURL: String? = nil,
        spoonacularScore: Double? = nil,
        spoonacularSourceURL: String? = nil,
        summary: String? = nil,
        taste: Taste? = nil,
        sustainable: Bool? = nil,
        vegan: Bool? = nil,
        vegetarian: Bool? = nil,
        veryHealthy: Bool? = nil,
        veryPopular: Bool? = nil,
        weightWatcherSmartPoints: Int? = nil,
        isFavorite: Bool? = nil
    ) {
        self.id = id
        self.title = title
        self.aggregateLikes = aggregateLikes
        self.analyzedInstructions = analyzedInstructions
        self.cheap = cheap
        self.cookingMinutes = cookingMinutes
        self.creditsText = creditsText
        self.cuisines = cuisines
        self.dairyFree = dairyFree
        self.diets = diets
        self.dishTypes = dishTypes
        self.extendedIngredients = extendedIngredients
        self.gaps = gaps
        self.glutenFree = glutenFree
        self.healthScore = healthScore
        self.image = image
        self.imageType = imageType
        self.instructions = instructions
        self.lowFodmap = lowFodmap
        self.nutrition = nutrition
        self.occasions = occasions
        self.originalID = originalID
        self.preparationMinutes = preparationMinutes
        self.pricePerServing = pricePerServing
        self.readyInMinutes = readyInMinutes
        self.servings = servings
        self.sourceName = sourceName
        self.sourceURL = sourceURL
        self.spoonacularScore = spoonacularScore
        self.spoonacularSourceURL = spoonacularSourceURL
        self.summary = summary
        self.taste = taste
        self.sustainable = sustainable
        self.vegan = vegan
        self.vegetarian = vegetarian
        self.veryHealthy = veryHealthy
        self.veryPopular = veryPopular
        self.weightWatcherSmartPoints = weightWatcherSmartPoints
        self.isFavorite = isFavorite
    }

    static func == (lhs: Recipe, rhs: Recipe) -> Bool {
        lhs.id == rhs.id
        && lhs.title == rhs.title
        && lhs.extendedIngredients == rhs.extendedIngredients
    }
}

// MARK: - AnalyzedInstruction
struct AnalyzedInstruction: Codable, Hashable {
    let name: String?
    let steps: [Step]?
}

// MARK: - Step
struct Step: Codable, Hashable {
    let equipment, ingredients: [Ent]?
    let number: Int?
    let step: String?
    let length: Length?
}

// MARK: - Ent
struct Ent: Codable, Hashable {
    let id: Int?
    let image: String?
    let localizedName, name: String?
}

// MARK: - Length
struct Length: Codable, Hashable {
    let number: Int?
    let unit: String?
}

// MARK: - ExtendedIngredient
struct ExtendedIngredient: Codable, Equatable, Hashable, Identifiable {
    static func == (lhs: ExtendedIngredient, rhs: ExtendedIngredient) -> Bool {
        lhs.id == rhs.id
        && lhs.name == rhs.name
        && lhs.image == rhs.image
    }
    
    let aisle: String?
    let amount: Double?
    let consistency: Consistency?
    let id: Int
    let image: String?
    let measures: Measures?
    let meta: [String]?
    let name, nameClean, original, originalName: String?
    let unit: String?

    var imageURL: URL? {
        guard let image else { return nil }
        return URL(string: "https://img.spoonacular.com/ingredients_100x100/\(image)")
    }
}

enum Consistency: String, Codable, Hashable {
    case liquid = "LIQUID"
    case solid = "SOLID"
}

// MARK: - Measures
struct Measures: Codable, Hashable {
    let metric, us: Metric?
}

// MARK: - Metric
struct Metric: Codable, Hashable {
    let amount: Double?
    let unitLong, unitShort: String?
}

// MARK: - Nutrition
struct Nutrition: Codable, Hashable {
    struct Ingredient: Codable, Hashable {
        let amount: Double?
        let id: Int?
        let name: String?
        let nutrients: [Nutrient]?
        let unit: String?
    }

    struct Nutrient: Codable, Hashable {
        let amount: Double?
        let name: String?
        let unit: Unit?
        let percentOfDailyNeeds: Double?
    }

    let caloricBreakdown: CaloricBreakdown?
    let flavonoids: [Nutrient]?
    let ingredients: [Ingredient]?
    let nutrients, properties: [Nutrient]?
    let weightPerServing: WeightPerServing?
}

// MARK: - CaloricBreakdown
struct CaloricBreakdown: Codable, Hashable {
    let percentCarbs, percentFat, percentProtein: Double?
}


enum Unit: String, Codable {
    case empty = ""
    case g = "g"
    case iu = "IU"
    case kcal = "kcal"
    case mg = "mg"
    case unit = "%"
    case µg = "µg"
}

// MARK: - WeightPerServing
struct WeightPerServing: Codable, Hashable {
    let amount: Int?
    let unit: Unit?
}

// MARK: - Taste
struct Taste: Codable, Hashable {
    let bitterness: Double?
    let fattiness: Double?
    let saltiness: Double?
    let savoriness: Double?
    let sourness: Double?
    let spiciness: Double?
    let sweetness: Double?
}
