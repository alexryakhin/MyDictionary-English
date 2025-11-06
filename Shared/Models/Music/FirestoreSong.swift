//
//  FirestoreSong.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin
//

import Foundation
import FirebaseFirestore

/// Public/shared song metadata stored in Firestore
/// Path: songs/{language.englishName.lowercased()}/{songId}
/// Accessible to all users
struct FirestoreSong: Codable {
    let id: String
    let title: String
    let artist: String
    let cefrLevel: CEFRLevel // CEFR level (A1, A2, B1, etc.)
    let appleMusicId: String? // Optional Apple Music ID
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case artist
        case cefrLevel = "cefr_level"
        case appleMusicId = "apple_music_id"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        artist = try container.decode(String.self, forKey: .artist)
        cefrLevel = try container.decode(CEFRLevel.self, forKey: .cefrLevel)
        appleMusicId = try container.decodeIfPresent(String.self, forKey: .appleMusicId)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(artist, forKey: .artist)
        try container.encode(cefrLevel, forKey: .cefrLevel)
        try container.encodeIfPresent(appleMusicId, forKey: .appleMusicId)
    }
}

