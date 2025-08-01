//
//  Word.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import Foundation

struct Word: Identifiable, Hashable {
    let word: String
    var definition: String
    var partOfSpeech: PartOfSpeech
    var phonetic: String
    let id: String
    let timestamp: Date
    var examples: [String]
    var isFavorite: Bool

    init(
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
