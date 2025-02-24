//
//  PartOfSpeech.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 2/24/25.
//

import Foundation

enum PartOfSpeech: String, CaseIterable, Codable {
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
    case auxiliaryVerb = "auxiliary-verb"
    case conjunction
    case definiteArticle = "definite-article"
    case familyName = "family-name"
    case givenName = "given-name"
    case idiom
    case imperative
    case nounPlural = "noun-plural"
    case nounPossessive = "noun-posessive"
    case pastParticiple = "past-participle"
    case phrasalPrefix = "phrasal-prefix"
    case properNoun = "proper-noun"
    case properNounPlural = "proper-noun-plural"
    case properNounPossessive = "proper-noun-posesessive"
    case suffix
    case verbIntransitive = "verb-intransitive"
    case verbTransitive = "verb-transitive"
    case unknown // Handles unexpected values

    /// Custom initializer that prevents decoding from failing.
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        self = PartOfSpeech(rawValue: rawValue) ?? .unknown
    }

    /// Custom encoding to preserve unknown values.
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.rawValue)
    }
}
