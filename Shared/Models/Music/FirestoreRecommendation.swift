//
//  FirestoreRecommendation.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin
//

import Foundation

/// Recommendation data structure stored in Firestore
/// Path: recommendationItems/{languageCode}/{cefrLevel}
struct FirestoreRecommendation: Codable {
    let languageCode: String
    let cefrLevel: String
    let artists: [RecommendationArtist]
    let albums: [RecommendationAlbum]
    let songs: [RecommendationSong]
    let generatedAt: Date
    let version: Int
    
    enum CodingKeys: String, CodingKey {
        case languageCode = "language_code"
        case cefrLevel = "cefr_level"
        case artists
        case albums
        case songs
        case generatedAt = "generated_at"
        case version
    }
}

/// Artist recommendation stored in Firestore
/// Only stores names and reasons - IDs and artwork URLs are fetched dynamically from Apple Music
struct RecommendationArtist: Codable, Identifiable, Hashable {
    let id: String // Generated ID for Firestore (not Apple Music ID)
    let name: String
    let reason: String? // Why this artist was recommended
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case reason
    }
    
    init(name: String, reason: String?) {
        self.id = UUID().uuidString
        self.name = name
        self.reason = reason
    }
}

/// Album recommendation stored in Firestore
/// Only stores names and reasons - IDs and artwork URLs are fetched dynamically from Apple Music
struct RecommendationAlbum: Codable, Identifiable, Hashable {
    let id: String // Generated ID for Firestore (not Apple Music ID)
    let name: String
    let artist: String
    let reason: String? // Why this album was recommended
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case artist
        case reason
    }
    
    init(name: String, artist: String, reason: String?) {
        self.id = UUID().uuidString
        self.name = name
        self.artist = artist
        self.reason = reason
    }
}

/// Song recommendation stored in Firestore
/// Only stores names and reasons - IDs and artwork URLs are fetched dynamically from Apple Music
struct RecommendationSong: Codable, Identifiable, Hashable {
    let id: String // Generated ID for Firestore (not Apple Music ID)
    let title: String
    let artist: String
    let reason: String? // Why this song was recommended
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case artist
        case reason
    }
    
    init(title: String, artist: String, reason: String?) {
        self.id = UUID().uuidString
        self.title = title
        self.artist = artist
        self.reason = reason
    }
}

