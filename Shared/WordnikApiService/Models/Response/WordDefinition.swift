//
//  WordDefinition.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 2/24/25.
//

import Foundation

struct WordDefinition: Codable, Identifiable {
    let id: String?
    let partOfSpeech: PartOfSpeech?
    let text: String?
}
// TODO:  filter definitions that has xref in there.
