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
}
