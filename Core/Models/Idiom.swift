//
//  Idiom.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import Foundation

public struct Idiom: Identifiable, Hashable {
    public let id: String
    public var idiom: String
    public var definition: String
    public let timestamp: Date
    public var examples: [String]
    public var isFavorite: Bool

    public init(
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
