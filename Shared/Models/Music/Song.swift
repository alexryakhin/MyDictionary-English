//
//  Song.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin
//

import Foundation

struct Song: Identifiable, Codable, Hashable {
    let id: String
    let title: String
    let artist: String
    let album: String?
    let albumArtURL: URL? // Album artwork for display
    let duration: TimeInterval // Critical for LRCLIB matching
    let serviceId: String // Original service ID (Apple Music ID)
    let cefrLevel: CEFRLevel? // CEFR level if known (from Firebase/OpenAI recommendations or hook generation)
    
    init(
        id: String,
        title: String,
        artist: String,
        album: String? = nil,
        albumArtURL: URL? = nil,
        duration: TimeInterval,
        serviceId: String,
        cefrLevel: CEFRLevel? = nil
    ) {
        self.id = id
        self.title = title
        self.artist = artist
        self.album = album
        self.albumArtURL = albumArtURL
        self.duration = duration
        self.serviceId = serviceId
        self.cefrLevel = cefrLevel
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case artist
        case album
        case albumArtURL
        case duration
        case serviceId
        case cefrLevel
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        artist = try container.decode(String.self, forKey: .artist)
        album = try container.decodeIfPresent(String.self, forKey: .album)
        serviceId = try container.decode(String.self, forKey: .serviceId)
        duration = try container.decode(TimeInterval.self, forKey: .duration)
        
        // Decode CEFR level as enum from string
        if let cefrLevelString = try? container.decodeIfPresent(String.self, forKey: .cefrLevel) {
            cefrLevel = CEFRLevel(rawValue: cefrLevelString)
        } else {
            cefrLevel = nil
        }
        
        // Decode optional artwork URL
        if let albumArtURLString = try? container.decodeIfPresent(String.self, forKey: .albumArtURL) {
            albumArtURL = URL(string: albumArtURLString)
        } else {
            albumArtURL = nil
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(artist, forKey: .artist)
        try container.encodeIfPresent(album, forKey: .album)
        try container.encode(serviceId, forKey: .serviceId)
        try container.encode(duration, forKey: .duration)
        try container.encodeIfPresent(cefrLevel?.rawValue, forKey: .cefrLevel)
        try container.encodeIfPresent(albumArtURL?.absoluteString, forKey: .albumArtURL)
    }
}