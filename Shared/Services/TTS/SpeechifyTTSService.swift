//
//  SpeechifyTTSService.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/9/25.
//

import Foundation
import FirebaseAuth

final class SpeechifyTTSService {

    static let shared = SpeechifyTTSService()

    private let remoteConfigService = RemoteConfigService.shared
    private let baseURL = "https://api.sws.speechify.com/v1/audio/speech"
    
    private init() {
        // Initialize with Remote Config
    }
    
    func synthesizeSpeech(request: TTSRequest) async throws -> TTSResponse {
        guard request.provider == .speechify else {
            throw TTSError.invalidResponse
        }
        
        guard let apiKey = remoteConfigService.getSpeechifyAPIKey() else {
            throw TTSError.invalidAPIKey
        }
        
        // Check if user has premium access
        guard SubscriptionService.shared.isProUser else {
            throw TTSError.premiumFeatureRequired
        }
        
        let url = URL(string: baseURL)!
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Prepare request body
        let requestBody: [String: Any] = [
            "input": request.text,
            "voice_id": request.voice ?? "en-US-1", // Default voice
            "audio_format": request.audioFormat,
            "language": request.language,
            "model": request.model.rawValue // Use English model for better quality
        ]
        
        do {
            urlRequest.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            throw TTSError.invalidResponse
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: urlRequest)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw TTSError.networkError("Invalid response")
            }
            
            switch httpResponse.statusCode {
            case 200:
                return try parseSpeechifyResponse(data: data)
            case 401:
                throw TTSError.invalidAPIKey
            case 402:
                throw TTSError.premiumFeatureRequired
            case 403:
                throw TTSError.premiumFeatureRequired
            case 429:
                throw TTSError.rateLimitExceeded
            case 500:
                throw TTSError.networkError("Server error")
            default:
                throw TTSError.networkError("HTTP \(httpResponse.statusCode)")
            }
        } catch {
            if error is TTSError {
                throw error
            }
            throw TTSError.networkError(error.localizedDescription)
        }
    }
    
    private func parseSpeechifyResponse(data: Data) throws -> TTSResponse {
        do {
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            
            guard let audioDataString = json?["audio_data"] as? String,
                  let audioData = Data(base64Encoded: audioDataString),
                  let audioFormat = json?["audio_format"] as? String else {
                throw TTSError.invalidResponse
            }
            
            let billableCharacters = json?["billable_characters_count"] as? Int
            
            return TTSResponse(
                audioData: audioData,
                format: audioFormat,
                billableCharacters: billableCharacters
            )
        } catch {
            throw TTSError.invalidResponse
        }
    }
    
    // MARK: - Voice Management
    
    func getAvailableVoices() throws -> [SpeechifyVoice] {
        return try Bundle.main.decode("speechify-voices")
    }
    
    
    // MARK: - Cache Management
    
    func clearCache() {
        URLCache.shared.removeAllCachedResponses()
        print("🗑️ [Speechify] URL cache cleared")
    }
}

// MARK: - Speechify Voice Model

struct SpeechifyVoice: Codable, Identifiable {
    let id: String
    let displayName: String
    let locale: String
    let gender: String?
    let avatarImage: String?
    let previewAudio: String?
    let type: String?
    let models: [SpeechifyVoiceModel]
    let tags: [String]

    // Computed properties for backward compatibility
    var name: String { displayName }
    var language: String { locale }
    var description: String? { nil } // Not available in new structure

    var languageDisplayName: String {
        Locale.current.localizedString(forIdentifier: locale) ?? locale
    }

    // Get the best available preview audio URL
    var bestPreviewAudioURL: String? {
        // First try the main preview audio
        if let previewAudio = previewAudio, !previewAudio.isEmpty {
            return previewAudio
        }
        
        // Fall back to the first model's preview audio
        return models.first?.languages.first?.previewAudio
    }

    // Helper methods for filtering
    var hasTag: (String) -> Bool {
        return { tag in
            self.tags.contains { $0.localizedCaseInsensitiveContains(tag) }
        }
    }

    var tagCategories: [String: [String]] {
        var categories: [String: [String]] = [:]
        for tag in tags {
            let components = tag.split(separator: ":", maxSplits: 1)
            if components.count == 2 {
                let category = String(components[0])
                let value = String(components[1])
                if categories[category] == nil {
                    categories[category] = []
                }
                categories[category]?.append(value)
            }
        }
        return categories
    }

    // Get all available tag values for a specific category
    func tagValues(for category: String) -> [String] {
        return tagCategories[category] ?? []
    }

    // Check if voice has a specific tag category and value
    func hasTag(category: String, value: String) -> Bool {
        return tags.contains { $0.lowercased() == "\(category):\(value)".lowercased() }
    }

    enum CodingKeys: String, CodingKey {
        case id
        case displayName = "display_name"
        case locale
        case gender
        case avatarImage = "avatar_image"
        case previewAudio = "preview_audio"
        case type
        case models
        case tags
    }

    // MARK: - Speechify Voice Model

    struct SpeechifyVoiceModel: Codable {
        let name: String
        let languages: [SpeechifyLanguage]

        enum CodingKeys: String, CodingKey {
            case name
            case languages
        }
    }

    struct SpeechifyLanguage: Codable {
        let locale: String
        let previewAudio: String?

        enum CodingKeys: String, CodingKey {
            case locale
            case previewAudio = "preview_audio"
        }
    }

    // MARK: - Legacy Support

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = try container.decode(String.self, forKey: .id)
        self.displayName = try container.decode(String.self, forKey: .displayName)
        self.locale = try container.decode(String.self, forKey: .locale)
        self.gender = try container.decodeIfPresent(String.self, forKey: .gender)
        self.avatarImage = try container.decodeIfPresent(String.self, forKey: .avatarImage)
        self.previewAudio = try container.decodeIfPresent(String.self, forKey: .previewAudio)
        self.type = try container.decodeIfPresent(String.self, forKey: .type)
        self.models = try container.decode([SpeechifyVoiceModel].self, forKey: .models)
        self.tags = try container.decode([String].self, forKey: .tags)
    }

    // Manual initializer for fallback voices (legacy support)
    init(id: String, name: String, language: String, gender: String?, description: String?) {
        #if DEBUG
        self.id = id
        self.displayName = name
        self.locale = language
        self.gender = gender
        self.avatarImage = nil
        self.previewAudio = nil
        self.type = "shared"
        self.models = []
        self.tags = []
        #else
        fatalError("SpeechifyVoice manual initializer should not be used in release builds")
        #endif
    }

    // Initializer for Cloud Function response data (legacy support)
    init?(from voiceData: [String: Any]) {
        guard let id = voiceData["id"] as? String,
              let name = voiceData["display_name"] as? String,
              let language = voiceData["locale"] as? String else {
            return nil
        }

        self.id = id
        self.displayName = name
        self.locale = language
        self.gender = voiceData["gender"] as? String
        self.avatarImage = voiceData["avatar_image"] as? String
        self.previewAudio = voiceData["preview_audio"] as? String
        self.type = voiceData["type"] as? String
        self.models = []
        self.tags = voiceData["tags"] as? [String] ?? []
    }
}
