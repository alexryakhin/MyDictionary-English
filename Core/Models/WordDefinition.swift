//
//  WordDefinition.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/9/25.
//

import Foundation

struct WordDefinition: Identifiable {
    let id: String = UUID().uuidString
    let partOfSpeech: PartOfSpeech
    let text: String
    let examples: [String]

    init(
        partOfSpeech: PartOfSpeech,
        text: String,
        examples: [String] = []
    ) {
        self.partOfSpeech = partOfSpeech
        self.text = text
        self.examples = examples
    }
}
