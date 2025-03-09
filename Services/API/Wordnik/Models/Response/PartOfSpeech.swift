//
//  PartOfSpeech.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/9/25.
//

import Foundation
import Core

enum PartOfSpeech: String, Decodable {
    case noun
    case adjective
    case verb
    case adverb
    case interjection
    case pronoun
    case preposition
    case abbreviation
    case affix
    case article
    case auxiliaryVerb = "auxiliary verb"
    case conjunction
    case definiteArticle = "definite article"
    case familyName = "family name"
    case givenName = "given name"
    case idiom
    case imperative
    case nounPlural = "noun plural"
    case nounPossessive = "noun posessive"
    case pastParticiple = "past participle"
    case phrasalPrefix = "phrasal prefix"
    case properNoun = "proper noun"
    case properNounPlural = "proper noun plural"
    case properNounPossessive = "proper noun posesessive"
    case suffix
    case verbIntransitive = "intransitive verb"
    case verbTransitive = "transitive verb"
    case unknown // Handles unexpected values

    /// Custom initializer that prevents decoding from failing.
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        self = PartOfSpeech(rawValue: rawValue) ?? .unknown
    }

    var coreValue: Core.PartOfSpeech {
        switch self {
        case .adjective: .adjective
        case .adverb: .adverb
        case .pronoun: .pronoun
        case .preposition: .preposition
        case .verb, .auxiliaryVerb, .verbIntransitive, .verbTransitive: .verb
        case .conjunction: .conjunction
        case .noun, .nounPlural, .nounPossessive, .properNoun, .properNounPlural, .properNounPossessive, .familyName, .givenName: .noun
        case .interjection: .exclamation
        default: .unknown
        }
    }
}
