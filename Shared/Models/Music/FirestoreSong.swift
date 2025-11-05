//
//  FirestoreSong.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin
//

import Foundation
import FirebaseFirestore

/// Public/shared song metadata stored in Firestore
/// Accessible to all users, read-only for regular users
struct FirestoreSong: Codable {
    let id: String
    let title: String
    let artist: String
    let duration: TimeInterval
    let language: String
    let cefrBase: String // CEFR level (A1, A2, B1, etc.)
    let difficultyScore: Double // 0.0 to 1.0
    let themes: [String] // e.g. ["love", "dance"]
    let grammarTags: [String] // e.g. ["imperativo", "presente"]
    let embedding: [Float] // 384-dim embedding vector
    let lyricsHash: String // Hash of lyrics to detect changes
    let generatedAt: Date
    let generationCount: Int // How many users triggered generation
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case artist
        case duration
        case language
        case cefrBase = "cefr_base"
        case difficultyScore = "difficulty_score"
        case themes
        case grammarTags = "grammar_tags"
        case embedding
        case lyricsHash = "lyrics_hash"
        case generatedAt = "generated_at"
        case generationCount = "generation_count"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        artist = try container.decode(String.self, forKey: .artist)
        duration = try container.decode(TimeInterval.self, forKey: .duration)
        language = try container.decode(String.self, forKey: .language)
        cefrBase = try container.decode(String.self, forKey: .cefrBase)
        difficultyScore = try container.decode(Double.self, forKey: .difficultyScore)
        themes = try container.decode([String].self, forKey: .themes)
        grammarTags = try container.decode([String].self, forKey: .grammarTags)
        embedding = try container.decode([Float].self, forKey: .embedding)
        lyricsHash = try container.decode(String.self, forKey: .lyricsHash)
        
        // Handle Firestore Timestamp
        if let timestamp = try? container.decode(Timestamp.self, forKey: .generatedAt) {
            generatedAt = timestamp.dateValue()
        } else if let date = try? container.decode(Date.self, forKey: .generatedAt) {
            generatedAt = date
        } else {
            generatedAt = Date()
        }
        
        generationCount = try container.decode(Int.self, forKey: .generationCount)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(artist, forKey: .artist)
        try container.encode(duration, forKey: .duration)
        try container.encode(language, forKey: .language)
        try container.encode(cefrBase, forKey: .cefrBase)
        try container.encode(difficultyScore, forKey: .difficultyScore)
        try container.encode(themes, forKey: .themes)
        try container.encode(grammarTags, forKey: .grammarTags)
        try container.encode(embedding, forKey: .embedding)
        try container.encode(lyricsHash, forKey: .lyricsHash)
        try container.encode(Timestamp(date: generatedAt), forKey: .generatedAt)
        try container.encode(generationCount, forKey: .generationCount)
    }
}

