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
    
    var displayName: String {
        switch self {
        case .google:
            return "Google"
        case .speechify:
            return Loc.Tts.Settings.speechify
        }
    }
    
    var isPremium: Bool {
        switch self {
        case .google:
            return false
        case .speechify:
            return true
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

enum TTSError: Error {
    case invalidAPIKey
    case networkError(String)
    case audioError(String)
    case premiumFeatureRequired
    case invalidResponse
    case rateLimitExceeded
    case monthlyLimitExceeded
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
