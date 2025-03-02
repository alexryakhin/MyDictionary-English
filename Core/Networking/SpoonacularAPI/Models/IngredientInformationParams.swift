//
//  IngredientInformationParams.swift
//  PureBite
//
//  Created by Aleksandr Riakhin on 12/31/24.
//
import Foundation

struct IngredientInformationParams: SpoonacularAPIParams {
    let id: Int
    let amount: Double
    let unit: String

    init(id: Int, amount: Double? = nil, unit: String? = nil) {
        self.id = id
        self.amount = amount ?? 100
        self.unit = unit ?? "g"
    }

    func queryItems() -> [URLQueryItem] {
        var queryItems: [URLQueryItem] = []

        queryItems.append(URLQueryItem(name: "amount", value: String(amount)))
        queryItems.append(URLQueryItem(name: "unit", value: unit))

        return queryItems
    }
}
