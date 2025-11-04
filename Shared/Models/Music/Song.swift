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
    let albumArtURL: URL?
    let duration: TimeInterval // Critical for LRCLIB matching
    let previewURL: URL?
    let serviceType: MusicServiceType
    let serviceId: String // Original service ID
    
    init(
        id: String,
        title: String,
        artist: String,
        album: String? = nil,
        albumArtURL: URL? = nil,
        duration: TimeInterval,
        previewURL: URL? = nil,
        serviceType: MusicServiceType,
        serviceId: String
    ) {
        self.id = id
        self.title = title
        self.artist = artist
        self.album = album
        self.albumArtURL = albumArtURL
        self.duration = duration
        self.previewURL = previewURL
        self.serviceType = serviceType
        self.serviceId = serviceId
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case artist
        case album
        case albumArtURL
        case duration
        case previewURL
        case serviceType
        case serviceId
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        artist = try container.decode(String.self, forKey: .artist)
        album = try container.decodeIfPresent(String.self, forKey: .album)
        serviceType = try container.decode(MusicServiceType.self, forKey: .serviceType)
        serviceId = try container.decode(String.self, forKey: .serviceId)
        duration = try container.decode(TimeInterval.self, forKey: .duration)
        
        // Decode optional URLs
        if let albumArtURLString = try? container.decodeIfPresent(String.self, forKey: .albumArtURL) {
            albumArtURL = URL(string: albumArtURLString)
        } else {
            albumArtURL = nil
        }
        
        if let previewURLString = try? container.decodeIfPresent(String.self, forKey: .previewURL) {
            previewURL = URL(string: previewURLString)
        } else {
            previewURL = nil
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(artist, forKey: .artist)
        try container.encodeIfPresent(album, forKey: .album)
        try container.encode(serviceType, forKey: .serviceType)
        try container.encode(serviceId, forKey: .serviceId)
        try container.encode(duration, forKey: .duration)
        try container.encodeIfPresent(albumArtURL?.absoluteString, forKey: .albumArtURL)
        try container.encodeIfPresent(previewURL?.absoluteString, forKey: .previewURL)
    }
}

