//
//  CoreIdiom.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import Foundation

public struct CoreIdiom: Identifiable {
    public let id: UUID
    public let idiom: String
    public let definition: String
    public let timestamp: Date
    public let examples: [String]
    public let isFavorite: Bool

    public init(
        idiom: String,
        definition: String,
        id: UUID,
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
