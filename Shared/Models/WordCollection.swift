//
//  WordCollection.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 1/27/25.
//

import Foundation
import SwiftUI

/// Represents a single word within a word collection
struct WordCollectionItem: Codable, Identifiable, Hashable {
    let id: String
    let text: String
    let phonetics: String?
    let partOfSpeech: PartOfSpeech
    let definition: String
    let examples: [String]
    
    init(
        id: String = UUID().uuidString,
        text: String,
        phonetics: String? = nil,
        partOfSpeech: PartOfSpeech,
        definition: String,
        examples: [String] = []
    ) {
        self.id = id
        self.text = text
        self.phonetics = phonetics
        self.partOfSpeech = partOfSpeech
        self.definition = definition
        self.examples = examples
    }
}

/// Represents a collection of words with metadata
struct WordCollection: Codable, Identifiable, Hashable {
    let id: String
    let title: String
    let words: [WordCollectionItem]
    let level: CEFRLevel
    let tagValue: String
    let languageCode: String
    let description: String?
    let imageUrl: String?
    let localImageName: String?
    let isPremium: Bool
    let isFeatured: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case words
        case level
        case tagValue
        case languageCode
        case description
        case imageUrl
        case localImageName
        case isPremium
        case isFeatured
    }
    
    init(
        id: String = UUID().uuidString,
        title: String,
        words: [WordCollectionItem],
        level: CEFRLevel,
        tagValue: String,
        languageCode: String,
        description: String? = nil,
        imageUrl: String? = nil,
        localImageName: String? = nil,
        isPremium: Bool = false,
        isFeatured: Bool = false
    ) {
        self.id = id
        self.title = title
        self.words = words
        self.level = level
        self.tagValue = tagValue
        self.languageCode = languageCode
        self.description = description
        self.imageUrl = imageUrl
        self.localImageName = localImageName
        self.isPremium = isPremium
        self.isFeatured = isFeatured
    }
    
    // MARK: - Custom Decoding
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        words = try container.decode([WordCollectionItem].self, forKey: .words)
        level = try container.decode(CEFRLevel.self, forKey: .level)
        tagValue = try container.decode(String.self, forKey: .tagValue)
        languageCode = try container.decode(String.self, forKey: .languageCode)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        imageUrl = try container.decodeIfPresent(String.self, forKey: .imageUrl)
        localImageName = try container.decodeIfPresent(String.self, forKey: .localImageName)
        isPremium = try container.decodeIfPresent(Bool.self, forKey: .isPremium) ?? false
        isFeatured = try container.decodeIfPresent(Bool.self, forKey: .isFeatured) ?? false
    }
    
    /// Returns the number of words in the collection
    var wordCount: Int {
        return words.count
    }
    
    /// Returns a formatted word count string
    var wordCountText: String {
        Loc.Plurals.Words.wordsCount(wordCount)
    }

    var imageURL: URL? {
        guard let imageUrl else { return nil }
        return URL(string: imageUrl)
    }
    
    var levelDisplayName: String {
        level.displayName
    }
    
    var levelColor: Color {
        level.color
    }
}

/// Container for multiple word collections
struct WordCollectionsResponse: Codable {
    let collections: [WordCollection]
    let lastUpdated: String?
    let version: String?
    
    init(
        collections: [WordCollection],
        lastUpdated: String? = nil,
        version: String? = nil
    ) {
        self.collections = collections
        self.lastUpdated = lastUpdated
        self.version = version
    }
}
