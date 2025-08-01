//
//  PartOfSpeech.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/9/25.
//

import Foundation

enum PartOfSpeech: String, CaseIterable {
    case noun
    case verb
    case adjective
    case adverb
    case conjunction
    case pronoun
    case preposition
    case exclamation
    case unknown // Handles unexpected values
}
