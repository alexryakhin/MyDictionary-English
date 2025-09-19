//
//  WordCollection.swift
//  My Dictionary
//
//  Created by AI Assistant on 1/27/25.
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
    let level: WordLevel
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
        level: WordLevel,
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
        level = try container.decode(WordLevel.self, forKey: .level)
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
        return "\(wordCount) \(wordCount == 1 ? "word" : "words")"
    }

    var imageURL: URL? {
        guard let imageUrl else { return nil }
        return URL(string: imageUrl)
    }
}

/// Represents the difficulty level of a word collection
enum WordLevel: String, Codable, CaseIterable {
    case a1 = "A1"
    case a2 = "A2"
    case b1 = "B1"
    case b2 = "B2"
    case c1 = "C1"
    case c2 = "C2"
    
    /// Returns a display name for the level
    var displayName: String {
        return rawValue
    }
    
    /// Returns a description for the level
    var description: String {
        switch self {
        case .a1: "Beginner"
        case .a2: "Elementary"
        case .b1: "Intermediate"
        case .b2: "Upper Intermediate"
        case .c1: "Advanced"
        case .c2: "Proficiency"
        }
    }
    
    /// Returns the color associated with the level
    var color: Color {
        switch self {
        case .a1, .a2: .green
        case .b1, .b2: .orange
        case .c1, .c2: .red
        }
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
