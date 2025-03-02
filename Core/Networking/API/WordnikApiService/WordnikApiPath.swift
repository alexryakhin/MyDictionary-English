//
//  WordnikApiPath.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 2/24/25.
//

import Foundation

enum WordnikApiPath: ApiPath {
    // Word-based (11 methods)
//    case audio(word: String, params: AudioQueryParams?)
    case definitions(word: String, params: DefinitionsQueryParams?)
//    case etymologies(word: String)
//    case examples(word: String, params: ExamplesQueryParams?)
//    case frequency(word: String, params: FrequencyQueryParams?)
//    case hyphenation(word: String, params: HyphenationQueryParams?)
//    case phrases(word: String, params: PhrasesQueryParams?)
//    case pronunciations(word: String, params: PronunciationsQueryParams?)
//    case relatedWords(word: String, params: RelatedWordsQueryParams?)
//    case scrabbleScore(word: String)
//    case topExample(word: String)

    // Words-based (5 methods)
//    case randomWord(params: RandomWordQueryParams?)
//    case randomWords(params: RandomWordQueryParams?)
//    case reverseDictionary(query: String, params: SearchQueryParams?)
//    case search(query: String, params: SearchQueryParams?)
//    case wordOfTheDay(date: String?)

    var path: String {
        switch self {
        // Word-based (11 methods)
//        case .audio(let word, _): return "/word.json/\(word)/audio"
        case .definitions(let word, _): return "/word.json/\(word)/definitions"
//        case .etymologies(let word): return "/word.json/\(word)/etymologies"
//        case .examples(let word, _): return "/word.json/\(word)/examples"
//        case .frequency(let word, _): return "/word.json/\(word)/frequency"
//        case .hyphenation(let word, _): return "/word.json/\(word)/hyphenation"
//        case .phrases(let word, _): return "/word.json/\(word)/phrases"
//        case .pronunciations(let word, _): return "/word.json/\(word)/pronunciations"
//        case .relatedWords(let word, _): return "/word.json/\(word)/relatedWords"
//        case .scrabbleScore(let word): return "/word.json/\(word)/scrabbleScore"
//        case .topExample(let word): return "/word.json/\(word)/topExample"

        // Words-based (5 methods)
//        case .randomWord: return "/words.json/randomWord"
//        case .randomWords: return "/words.json/randomWords"
//        case .reverseDictionary: return "/words.json/reverseDictionary"
//        case .search: return "/words.json/search"
//        case .wordOfTheDay: return "/words.json/wordOfTheDay"
        }
    }

    var queryParams: [URLQueryItem]? {
        switch self {
        // Word-based (methods that have params)
//        case .audio(_, let params): return params?.queryItems
        case .definitions(_, let params): return params?.queryItems
//        case .examples(_, let params): return params?.queryItems
//        case .frequency(_, let params): return params?.queryItems
//        case .hyphenation(_, let params): return params?.queryItems
//        case .phrases(_, let params): return params?.queryItems
//        case .pronunciations(_, let params): return params?.queryItems
//        case .relatedWords(_, let params): return params?.queryItems

        // Words-based (methods that have params)
//        case .randomWord(let params): return params?.queryItems
//        case .randomWords(let params): return params?.queryItems
//        case .reverseDictionary(_, let params): return params?.queryItems
//        case .search(_, let params): return params?.queryItems

        // Methods without query params
//        default: return nil
        }
    }
}
