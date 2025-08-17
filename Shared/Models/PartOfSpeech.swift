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
        default: self = .unknown
        }
    }

    var displayName: String {
        switch self {
        case .noun: return Loc.PartOfSpeech.Full.noun.localized
        case .verb: return Loc.PartOfSpeech.Full.verb.localized
        case .adjective: return Loc.PartOfSpeech.Full.adjective.localized
        case .adverb: return Loc.PartOfSpeech.Full.adverb.localized
        case .conjunction: return Loc.PartOfSpeech.Full.conjunction.localized
        case .pronoun: return Loc.PartOfSpeech.Full.pronoun.localized
        case .preposition: return Loc.PartOfSpeech.Full.preposition.localized
        case .exclamation: return Loc.PartOfSpeech.Full.exclamation.localized
        case .unknown: return Loc.PartOfSpeech.Full.unknown.localized
        }
    }

    var displayNameShort: String {
        switch self {
        case .noun: return Loc.PartOfSpeech.Short.noun.localized
        case .verb: return Loc.PartOfSpeech.Short.verb.localized
        case .adjective: return Loc.PartOfSpeech.Short.adjective.localized
        case .adverb: return Loc.PartOfSpeech.Short.adverb.localized
        case .conjunction: return Loc.PartOfSpeech.Short.conjunction.localized
        case .pronoun: return Loc.PartOfSpeech.Short.pronoun.localized
        case .preposition: return Loc.PartOfSpeech.Short.preposition.localized
        case .exclamation: return Loc.PartOfSpeech.Short.exclamation.localized
        case .unknown: return Loc.PartOfSpeech.Short.unknown.localized
        }
    }
}
