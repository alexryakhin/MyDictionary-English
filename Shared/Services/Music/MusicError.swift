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
            return Loc.MusicDiscovering.Error.userProfileNotCompleted
        case .authenticationFailed(let message):
            return Loc.MusicDiscovering.Error.authenticationFailed(message)
        case .songNotFound:
            return Loc.MusicDiscovering.Error.songNotFound
        case .lyricsNotFound:
            return Loc.MusicDiscovering.Error.lyricsNotFound
        case .lyricsLanguageNotDetermined:
            return Loc.MusicDiscovering.Error.lyricsLanguageNotDetermined
        case .lessonNotFound:
            return Loc.MusicDiscovering.Error.lessonNotFound
        case .invalidDuration:
            return Loc.MusicDiscovering.Error.invalidDuration
        case .playbackNotSupported:
            return Loc.MusicDiscovering.Error.playbackNotSupported
        case .networkError(let message):
            return Loc.MusicDiscovering.Error.networkError(message)
        case .serviceUnavailable:
            return Loc.MusicDiscovering.Error.serviceUnavailable
        case .invalidResponse:
            return Loc.MusicDiscovering.Error.invalidResponse
        case .tokenRefreshFailed:
            return Loc.MusicDiscovering.Error.tokenRefreshFailed
        case .appleMusicNotRegistered:
            return Loc.MusicDiscovering.Error.appleMusicNotRegistered
        case .appleMusicSubscriptionRequired:
            return Loc.MusicDiscovering.Error.appleMusicSubscriptionRequired
        case .invalidCEFRLevel:
            return Loc.MusicDiscovering.Error.invalidCefrLevel
        case .noRecommendationsAvailable:
            return Loc.MusicDiscovering.Error.noRecommendationsAvailable
        case .premiumRequired:
            return Loc.MusicDiscovering.Error.premiumRequired
        case .hookGenerationFailed:
            return Loc.MusicDiscovering.Error.hookGenerationFailed
        }
    }
}

