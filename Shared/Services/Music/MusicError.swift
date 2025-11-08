//
//  MusicError.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin
//

import Foundation

enum MusicError: Error, LocalizedError, Hashable {
    case userProfileNotCompleted
    case authenticationFailed(String)
    case songNotFound
    case lyricsNotFound
    case lyricsLanguageNotDetermined
    case lessonNotFound
    case invalidDuration
    case playbackNotSupported
    case networkError(String)
    case serviceUnavailable
    case invalidResponse
    case tokenRefreshFailed
    case appleMusicNotRegistered
    case appleMusicSubscriptionRequired
    case invalidCEFRLevel
    case noRecommendationsAvailable
    case premiumRequired
    case hookGenerationFailed

    var errorDescription: String? {
        switch self {
        case .userProfileNotCompleted:
            return "User Profile not completed"
        case .authenticationFailed(let message):
            return "Authentication failed: \(message)"
        case .songNotFound:
            return "Song not found"
        case .lyricsNotFound:
            return "Lyrics not available for this song"
        case .lyricsLanguageNotDetermined:
            return "Lyrics language not determined"
        case .lessonNotFound:
            return "Lesson not found"
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
        case .appleMusicNotRegistered:
            return "This app needs to be registered for MusicKit in App Store Connect. Please contact support."
        case .appleMusicSubscriptionRequired:
            return "An Apple Music subscription is required to use this feature. You can subscribe in the Music app or Settings."
        case .invalidCEFRLevel:
            return "Invalid CEFR level"
        case .noRecommendationsAvailable:
            return "No recommendations available"
        case .premiumRequired:
            return "Premium access is required to use this feature"
        case .hookGenerationFailed:
            return "Failed to generate a preview for this song"
        }
    }
}

