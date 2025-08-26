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
    case interjection
    case idiom
    case phrase
    case unknown // Handles unexpected values

    init(rawValue: String?) {
        switch rawValue.orEmpty.lowercased() {
        case "noun": self = .noun
        case "verb": self = .verb
        case "adjective": self = .adjective
        case "adverb": self = .adverb
        case "conjunction": self = .conjunction
        case "pronoun": self = .pronoun
        case "preposition": self = .preposition
        case "exclamation": self = .exclamation
        case "interjection": self = .interjection
        case "idiom": self = .idiom
        case "phrase": self = .phrase
        default: self = .unknown
        }
    }

    var displayName: String {
        switch self {
        case .noun: return Loc.Words.PartOfSpeech.Full.noun
        case .verb: return Loc.Words.PartOfSpeech.Full.verb
        case .adjective: return Loc.Words.PartOfSpeech.Full.adjective
        case .adverb: return Loc.Words.PartOfSpeech.Full.adverb
        case .conjunction: return Loc.Words.PartOfSpeech.Full.conjunction
        case .pronoun: return Loc.Words.PartOfSpeech.Full.pronoun
        case .preposition: return Loc.Words.PartOfSpeech.Full.preposition
        case .exclamation: return Loc.Words.PartOfSpeech.Full.exclamation
        case .interjection: return Loc.Words.PartOfSpeech.Full.interjection
        case .idiom: return "Idiom"
        case .phrase: return "Phrase"
        case .unknown: return Loc.Words.PartOfSpeech.Full.unknown
        }
    }

    var displayNameShort: String {
        switch self {
        case .noun: return Loc.Words.PartOfSpeech.Short.noun
        case .verb: return Loc.Words.PartOfSpeech.Short.verb
        case .adjective: return Loc.Words.PartOfSpeech.Short.adjective
        case .adverb: return Loc.Words.PartOfSpeech.Short.adverb
        case .conjunction: return Loc.Words.PartOfSpeech.Short.conjunction
        case .pronoun: return Loc.Words.PartOfSpeech.Short.pronoun
        case .preposition: return Loc.Words.PartOfSpeech.Short.preposition
        case .exclamation: return Loc.Words.PartOfSpeech.Short.exclamation
        case .interjection: return Loc.Words.PartOfSpeech.Short.interjection
        case .idiom: return "Idiom"
        case .phrase: return "Phrase"
        case .unknown: return Loc.Words.PartOfSpeech.Short.unknown
        }
    }
    
    /// Returns true if this part of speech represents an expression (idiom or phrase)
    var isExpression: Bool {
        return self == .idiom || self == .phrase
    }
    
    /// Returns all standard word part-of-speech cases (excluding expressions)
    static var wordCases: [PartOfSpeech] {
        return allCases.filter { !$0.isExpression && $0 != .unknown }
    }
    
    /// Returns all expression part-of-speech cases
    static var expressionCases: [PartOfSpeech] {
        return [.idiom, .phrase]
    }
}
