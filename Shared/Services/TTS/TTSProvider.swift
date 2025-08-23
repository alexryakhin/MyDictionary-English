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
            return "Speechify"
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
        case .english:
            return "English"
        case .multilingual:
            return "Multilingual"
        }
    }

    var description: String {
        switch self {
        case .english:
            return "Speechify’s English text-to-speech model offers standard capabilities designed to deliver clear and natural voice output for reading texts. The model focuses on delivering a consistent user experience."
        case .multilingual:
            return "Multilingual model allows the usage of all supported languages and supports using multiple languages within a single sentence. The audio output of this model is distinctively different from other models."
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
