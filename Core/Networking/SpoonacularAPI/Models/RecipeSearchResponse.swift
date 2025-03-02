//
//  RecipeSearchResponse.swift
//  PureBite
//
//  Created by Aleksandr Riakhin on 6/16/24.
//

import Foundation

struct RecipeSearchResponse: Codable {
    let results: [Recipe]
    let totalResults: Int
    let offset: Int
    let number: Int
}
