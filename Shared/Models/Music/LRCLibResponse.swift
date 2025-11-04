//
//  LRCLibResponse.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin
//

import Foundation

struct LRCLibResponse: Codable {
    let id: Int?
    let trackName: String?
    let artistName: String?
    let albumName: String?
    let duration: Int? // Duration in seconds
    let instrumental: Bool
    let plainLyrics: String?
    let syncedLyrics: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case trackName
        case artistName
        case albumName
        case duration
        case instrumental
        case plainLyrics
        case syncedLyrics
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(Int.self, forKey: .id)
        trackName = try container.decodeIfPresent(String.self, forKey: .trackName)
        artistName = try container.decodeIfPresent(String.self, forKey: .artistName)
        albumName = try container.decodeIfPresent(String.self, forKey: .albumName)
        duration = try container.decodeIfPresent(Int.self, forKey: .duration)
        instrumental = try container.decodeIfPresent(Bool.self, forKey: .instrumental) ?? false
        plainLyrics = try container.decodeIfPresent(String.self, forKey: .plainLyrics)
        syncedLyrics = try container.decodeIfPresent(String.self, forKey: .syncedLyrics)
    }
    
    /// Converts to SongLyrics model
    func toSongLyrics() -> SongLyrics {
        return SongLyrics(
            plainLyrics: plainLyrics,
            syncedLyrics: syncedLyrics,
            instrumental: instrumental
        )
    }
}

/// LRCLIB search response model
struct LRCLibSearchResponse: Codable {
    let data: [LRCLibSearchResult]
}

struct LRCLibSearchResult: Codable {
    let id: Int
    let trackName: String
    let artistName: String
    let albumName: String?
    let duration: Int
    
    enum CodingKeys: String, CodingKey {
        case id
        case trackName
        case artistName
        case albumName
        case duration
    }
}

