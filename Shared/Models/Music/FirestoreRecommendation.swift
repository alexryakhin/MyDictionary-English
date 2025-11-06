//
//  FirestoreRecommendation.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin
//

import Foundation

/// Recommendation data structure stored in Firestore
/// Path: recommendationSongs/{language.englishName.lowercased()}/{cefrLevel}
struct FirestoreRecommendation: Codable {
    let languageCode: String
    let cefrLevel: CEFRLevel
    let songs: [RecommendationSong]
    let generatedAt: Date
    let version: Int
    
    enum CodingKeys: String, CodingKey {
        case languageCode = "language_code"
        case cefrLevel = "cefr_level"
        case songs
        case generatedAt = "generated_at"
        case version
    }
}

/// Song recommendation stored in Firestore
struct RecommendationSong: Codable, Identifiable, Hashable {
    let id: String // Generated ID for Firestore (not Apple Music ID)
    let title: String
    let artist: String
    let cefrLevel: CEFRLevel // CEFR level (A1, A2, B1, etc.)
    let appleMusicId: String? // Optional Apple Music ID
    let reason: String? // Why this song was recommended
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case artist
        case cefrLevel = "cefr_level"
        case appleMusicId = "apple_music_id"
        case reason
    }
    
    init(
        title: String,
        artist: String,
        cefrLevel: CEFRLevel,
        appleMusicId: String? = nil,
        reason: String? = nil
    ) {
        self.id = UUID().uuidString
        self.title = title
        self.artist = artist
        self.cefrLevel = cefrLevel
        self.appleMusicId = appleMusicId
        self.reason = reason
    }
    
    init(
        id: String,
        title: String,
        artist: String,
        cefrLevel: CEFRLevel,
        appleMusicId: String? = nil,
        reason: String? = nil
    ) {
        self.id = id
        self.title = title
        self.artist = artist
        self.cefrLevel = cefrLevel
        self.appleMusicId = appleMusicId
        self.reason = reason
    }
}

