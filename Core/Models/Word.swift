//
//  Word.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

public struct Word: Identifiable, Hashable {
    public let word: String
    public var definition: String
    public var partOfSpeech: PartOfSpeech
    public var phonetic: String
    public let id: String
    public let timestamp: Date
    public var examples: [String]
    public var isFavorite: Bool

    public init(
        word: String,
        definition: String,
        partOfSpeech: PartOfSpeech,
        phonetic: String,
        id: String,
        timestamp: Date,
        examples: [String],
        isFavorite: Bool
    ) {
        self.word = word
        self.definition = definition
        self.partOfSpeech = partOfSpeech
        self.phonetic = phonetic
        self.id = id
        self.timestamp = timestamp
        self.isFavorite = isFavorite
        self.examples = examples
    }
}
