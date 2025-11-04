//
//  MusicServiceType.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin
//

import Foundation

enum MusicServiceType: String, CaseIterable, Codable {
    case appleMusic = "apple_music"
    case spotify = "spotify"
    
    var displayName: String {
        switch self {
        case .appleMusic:
            return "Apple Music"
        case .spotify:
            return "Spotify"
        }
    }
}

