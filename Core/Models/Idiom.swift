//
//  Idiom.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import Foundation

struct Idiom: Identifiable, Hashable {
    let id: String
    var idiom: String
    var definition: String
    let timestamp: Date
    var examples: [String]
    var isFavorite: Bool

    init(
        idiom: String,
        definition: String,
        id: String,
        timestamp: Date,
        examples: [String],
        isFavorite: Bool
    ) {
        self.definition = definition
        self.id = id
        self.idiom = idiom
        self.isFavorite = isFavorite
        self.timestamp = timestamp
        self.examples = examples
    }
}
