//
//  SongLyrics.swift
//  My Dictionary
//
//  Created by AI Assistant
//

import Foundation

struct SongLyrics: Codable {
    let plainLyrics: String?
    let syncedLyrics: String? // LRC format: [00:17.12] ... [03:20.31] ...
    let instrumental: Bool
    
    init(
        plainLyrics: String? = nil,
        syncedLyrics: String? = nil,
        instrumental: Bool = false
    ) {
        self.plainLyrics = plainLyrics
        self.syncedLyrics = syncedLyrics
        self.instrumental = instrumental
    }
    
    /// Returns true if lyrics are available (not instrumental and has either plain or synced lyrics)
    var hasLyrics: Bool {
        return !instrumental && (plainLyrics != nil || syncedLyrics != nil)
    }
    
    /// Returns the best available lyrics (prefers synced, falls back to plain)
    var bestLyrics: String? {
        return syncedLyrics ?? plainLyrics
    }
}

