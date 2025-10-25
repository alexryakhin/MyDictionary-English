//
//  TTSProvider.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/9/25.
//

import Foundation

enum TTSProvider: String, CaseIterable {
    case google = "google"
    case speechify = "speechify"
    case system = "system"
    
    var displayName: String {
        switch self {
        case .google:
            return "Google"
        case .speechify:
            return Loc.Tts.Settings.speechify
        case .system:
            return "System"
        }
    }
    
    var isPremium: Bool {
        switch self {
        case .google:
            return false
        case .speechify:
            return true
        case .system:
            return false
        }
    }
}

enum SpeechifyModel: String, CaseIterable {
    case english = "simba-english"
    case multilingual = "simba-multilingual"

    var displayName: String {
        switch self {
        case .english: Loc.Tts.Models.english
        case .multilingual: Loc.Tts.Models.multilingual
        }
    }

    var description: String {
        switch self {
        case .english: Loc.Tts.Models.englishDescription
        case .multilingual: Loc.Tts.Models.multilingualDescription
        }
    }
}

enum TTSError: Error, LocalizedError {
    case invalidAPIKey
    case networkError(String)
    case audioError(String)
    case premiumFeatureRequired
    case invalidResponse
    case rateLimitExceeded
    case monthlyLimitExceeded
    
    var errorDescription: String? {
        switch self {
        case .invalidAPIKey:
            return "Invalid or missing API key"
        case .networkError(let message):
            return "Network error: \(message)"
        case .audioError(let message):
            return "Audio error: \(message)"
        case .premiumFeatureRequired:
            return "Premium subscription required"
        case .invalidResponse:
            return "Invalid response from TTS service"
        case .rateLimitExceeded:
            return "Rate limit exceeded"
        case .monthlyLimitExceeded:
            return "Monthly usage limit exceeded"
        }
    }
}

struct TTSRequest {
    let text: String
    let language: String
    let voice: String?
    let provider: TTSProvider
    let model: SpeechifyModel
    let audioFormat: String
}

struct TTSResponse {
    let audioData: Data
    let format: String
    let billableCharacters: Int?
}
