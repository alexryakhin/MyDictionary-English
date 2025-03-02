//
//  SearchIngredientsParams.swift
//  PureBite
//
//  Created by Aleksandr Riakhin on 6/22/24.
//

import Foundation

struct SearchIngredientsParams: SpoonacularAPIParams {
    // The search query for the ingredient.
    let query: String?
    let minCalories: Int?
    let maxCalories: Int?
    let minCarbs: Int?
    let maxCarbs: Int?
    let minProtein: Int?
    let maxProtein: Int?
    let minFat: Int?
    let maxFat: Int?
    let sort: SortingOption
    let sortDirection: String?
    let intolerances: [Intolerance]
    let metaInformation: Bool?
    let offset: Int?
    let number: Int?

    init(
        query: String? = nil,
        minCalories: Int? = nil,
        maxCalories: Int? = nil,
        minCarbs: Int? = nil,
        maxCarbs: Int? = nil,
        minProtein: Int? = nil,
        maxProtein: Int? = nil,
        minFat: Int? = nil,
        maxFat: Int? = nil,
        sort: SortingOption = .empty,
        sortDirection: String? = nil,
        intolerances: [Intolerance] = [],
        metaInformation: Bool? = nil,
        offset: Int? = nil,
        number: Int? = nil
    ) {
        self.query = query
        self.minCalories = minCalories
        self.maxCalories = maxCalories
        self.minCarbs = minCarbs
        self.maxCarbs = maxCarbs
        self.minProtein = minProtein
        self.maxProtein = maxProtein
        self.minFat = minFat
        self.maxFat = maxFat
        self.sort = sort
        self.sortDirection = sortDirection
        self.intolerances = intolerances
        self.metaInformation = metaInformation
        self.offset = offset
        self.number = number
    }

    func queryItems() -> [URLQueryItem] {
        var queryItems: [URLQueryItem] = []

        if let query = query {
            queryItems.append(URLQueryItem(name: "query", value: query))
        }
        if let minCalories = minCalories {
            queryItems.append(URLQueryItem(name: "minCalories", value: String(minCalories)))
        }
        if let maxCalories = maxCalories {
            queryItems.append(URLQueryItem(name: "maxCalories", value: String(maxCalories)))
        }
        if let minCarbs = minCarbs {
            queryItems.append(URLQueryItem(name: "minCarbs", value: String(minCarbs)))
        }
        if let maxCarbs = maxCarbs {
            queryItems.append(URLQueryItem(name: "maxCarbs", value: String(maxCarbs)))
        }
        if let minProtein = minProtein {
            queryItems.append(URLQueryItem(name: "minProtein", value: String(minProtein)))
        }
        if let maxProtein = maxProtein {
            queryItems.append(URLQueryItem(name: "maxProtein", value: String(maxProtein)))
        }
        if let minFat = minFat {
            queryItems.append(URLQueryItem(name: "minFat", value: String(minFat)))
        }
        if let maxFat = maxFat {
            queryItems.append(URLQueryItem(name: "maxFat", value: String(maxFat)))
        }
        if sort != .empty {
            queryItems.append(URLQueryItem(name: "sort", value: sort.rawValue))
        }
        if let sortDirection = sortDirection {
            queryItems.append(URLQueryItem(name: "sortDirection", value: sortDirection))
        }
        if !intolerances.isEmpty {
            queryItems.append(URLQueryItem(name: "intolerances", value: intolerances.toString))
        }
        if let metaInformation = metaInformation {
            queryItems.append(URLQueryItem(name: "metaInformation", value: String(metaInformation)))
        }
        if let offset = offset {
            queryItems.append(URLQueryItem(name: "offset", value: String(offset)))
        }
        if let number = number {
            queryItems.append(URLQueryItem(name: "number", value: String(number)))
        }

        return queryItems
    }
}
