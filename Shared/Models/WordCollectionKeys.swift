//
//  WordCollectionKeys.swift
//  My Dictionary
//
//  Created by AI Assistant on 1/27/25.
//

import Foundation

/// Enum containing Firebase Remote Config keys for word collections
enum WordCollectionKeys: String, CaseIterable {
    case englishWordCollection = "english_word_collection"
    case russianWordCollection = "russian_word_collection"
    case spanishWordCollection = "spanish_word_collection"
    case frenchWordCollection = "french_word_collection"
    case germanWordCollection = "german_word_collection"
    case italianWordCollection = "italian_word_collection"
    case portugueseWordCollection = "portuguese_word_collection"
    case chineseWordCollection = "chinese_word_collection"
    case japaneseWordCollection = "japanese_word_collection"
    case koreanWordCollection = "korean_word_collection"
    
    /// Returns the language code for the collection
    var languageCode: String {
        switch self {
        case .englishWordCollection:
            return "en"
        case .russianWordCollection:
            return "ru"
        case .spanishWordCollection:
            return "es"
        case .frenchWordCollection:
            return "fr"
        case .germanWordCollection:
            return "de"
        case .italianWordCollection:
            return "it"
        case .portugueseWordCollection:
            return "pt"
        case .chineseWordCollection:
            return "zh"
        case .japaneseWordCollection:
            return "ja"
        case .koreanWordCollection:
            return "ko"
        }
    }
    
    /// Returns a display name for the collection
    var displayName: String {
        Locale.current.localizedString(forLanguageCode: languageCode)?.capitalized ?? languageCode.uppercased()
    }
}
