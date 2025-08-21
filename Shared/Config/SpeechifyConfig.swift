//
//  SpeechifyConfig.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/9/25.
//

import Foundation

struct SpeechifyConfig {
    
    // MARK: - API Configuration

    static let baseURL = "https://api.sws.speechify.com"
    static let apiVersion = "v1"
    
    // MARK: - Default Settings
    
    static let defaultVoice = "en-US-1"
    static let defaultAudioFormat = "wav"
    static let defaultModel = "simba-english"
    
    // MARK: - Rate Limiting
    
    static let maxCharactersPerRequest = 5000
    static let maxRequestsPerMinute = 60
    
    // MARK: - Voice Categories
    
    static let voiceCategories = [
        "en-US": "English (US)",
        "en-GB": "English (UK)",
        "es-ES": "Spanish",
        "fr-FR": "French",
        "de-DE": "German",
        "it-IT": "Italian",
        "pt-BR": "Portuguese (Brazil)",
        "ja-JP": "Japanese",
        "ko-KR": "Korean",
        "zh-CN": "Chinese (Simplified)"
    ]
    
    // MARK: - Validation
    
    static var isConfigured: Bool {
        return AppConfig.Speechify.apiKey.isNotEmpty
    }
    
    static func validateText(_ text: String) -> Bool {
        return text.isNotEmpty && text.count <= maxCharactersPerRequest
    }
}
