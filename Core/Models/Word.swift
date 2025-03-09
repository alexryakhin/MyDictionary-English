//
//  Word.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

public struct Word: Identifiable {
    public let word: String
    public let definition: String
    public let partOfSpeech: String
    public let phonetic: String?
    public let id: UUID
    public let timestamp: Date
    public let examples: [String]
    public let isFavorite: Bool

    public init(
        word: String,
        definition: String,
        partOfSpeech: String,
        phonetic: String? = nil,
        id: UUID,
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
