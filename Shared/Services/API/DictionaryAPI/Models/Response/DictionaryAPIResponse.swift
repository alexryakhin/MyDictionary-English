//
//  DictionaryAPIResponse.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/9/25.
//

import Foundation

enum DictionaryAPI {
    struct Response: Decodable {
        let word: String
        let phonetics: [Phonetic]
        let meanings: [Meaning]
        let license: License?
        let sourceUrls: [String]?
    }

    struct Phonetic: Decodable {
        let text: String?
        let audio: String?
        let sourceUrl: String?
        let license: License?
    }

    struct Meaning: Decodable {
        let partOfSpeech: String
        let definitions: [Definition]
        let synonyms: [String]?
        let antonyms: [String]?
    }

    struct Definition: Decodable {
        let definition: String
        let example: String?
        let synonyms: [String]?
        let antonyms: [String]?
    }

    struct License: Decodable {
        let name: String
        let url: String
    }
}

