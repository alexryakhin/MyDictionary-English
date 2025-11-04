//
//  MusicError.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin
//

import Foundation

enum MusicError: Error, LocalizedError {
    case authenticationRequired
    case authenticationFailed(String)
    case songNotFound
    case lyricsNotFound
    case invalidDuration
    case playbackNotSupported
    case networkError(String)
    case serviceUnavailable
    case invalidResponse
    case tokenRefreshFailed
    
    var errorDescription: String? {
        switch self {
        case .authenticationRequired:
            return "Authentication is required to access music services"
        case .authenticationFailed(let message):
            return "Authentication failed: \(message)"
        case .songNotFound:
            return "Song not found"
        case .lyricsNotFound:
            return "Lyrics not available for this song"
        case .invalidDuration:
            return "Invalid song duration"
        case .playbackNotSupported:
            return "Playback is not supported for this song"
        case .networkError(let message):
            return "Network error: \(message)"
        case .serviceUnavailable:
            return "Music service is currently unavailable"
        case .invalidResponse:
            return "Invalid response from music service"
        case .tokenRefreshFailed:
            return "Failed to refresh authentication token"
        }
    }
}

