//
//  WordDefinition.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/9/25.
//

import Foundation

public struct WordDefinition: Identifiable {
    public let id: String = UUID().uuidString
    public let partOfSpeech: PartOfSpeech
    public let text: String
    public let examples: [String]

    public init(
        partOfSpeech: PartOfSpeech,
        text: String,
        examples: [String] = []
    ) {
        self.partOfSpeech = partOfSpeech
        self.text = text
        self.examples = examples
    }
}
