//
//  SpeechifyTTSService.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/9/25.
//

import Foundation

final class SpeechifyTTSService {
    
    private let apiKey: String
    private let baseURL = "https://api.sws.speechify.com/v1/audio/speech"
    
    init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    func synthesizeSpeech(request: TTSRequest) async throws -> TTSResponse {
        guard request.provider == .speechify else {
            throw TTSError.invalidResponse
        }
        
        guard !apiKey.isEmpty else {
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
    
    func getAvailableVoices() async throws -> [SpeechifyVoice] {
        guard SubscriptionService.shared.isProUser else {
            throw TTSError.premiumFeatureRequired
        }
        
        guard !apiKey.isEmpty else {
            print("⚠️ [Speechify] API key is empty, returning fallback voices")
            return getFallbackVoices()
        }
        
        let url = URL(string: "https://api.sws.speechify.com/v1/voices")!
        var urlRequest = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad)
        urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: urlRequest)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw TTSError.networkError("Invalid response")
            }
            
            // Debug: Print response for troubleshooting
            print("🔍 [Speechify] Voice API Response Status: \(httpResponse.statusCode)")

            switch httpResponse.statusCode {
            case 200:
                do {
                    let voices = try JSONDecoder().decode([SpeechifyVoice].self, from: data)
                    print("✅ [Speechify] Successfully loaded \(voices.count) voices")
                    return voices
                } catch {
                    print("❌ [Speechify] JSON Decoding Error: \(error)")
                    
                    // For debugging, let's see what the actual response looks like
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("🔍 [Speechify] Raw API Response: \(responseString)")
                    }
                    
                    throw TTSError.networkError("Failed to parse voices response: \(error.localizedDescription)")
                }
            case 401:
                throw TTSError.invalidAPIKey
            case 403:
                throw TTSError.premiumFeatureRequired
            case 429:
                throw TTSError.rateLimitExceeded
            default:
                throw TTSError.networkError("HTTP \(httpResponse.statusCode): Failed to fetch voices")
            }
        } catch {
            if error is TTSError {
                throw error
            }
            throw TTSError.networkError("Failed to fetch voices: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Cache Management
    
    func clearCache() {
        URLCache.shared.removeAllCachedResponses()
        print("🗑️ [Speechify] URL cache cleared")
    }
    
    // MARK: - Fallback Voices
    
    private func getFallbackVoices() -> [SpeechifyVoice] {
        return [
            SpeechifyVoice(id: "en-US-1", name: "Sarah", language: "en-US", gender: "female", description: "Professional American English"),
            SpeechifyVoice(id: "en-US-2", name: "Mike", language: "en-US", gender: "male", description: "Clear American English"),
            SpeechifyVoice(id: "en-GB-1", name: "Emma", language: "en-GB", gender: "female", description: "British English"),
            SpeechifyVoice(id: "en-GB-2", name: "James", language: "en-GB", gender: "male", description: "Professional British English"),
            SpeechifyVoice(id: "es-ES-1", name: "Maria", language: "es-ES", gender: "female", description: "Spanish"),
            SpeechifyVoice(id: "fr-FR-1", name: "Sophie", language: "fr-FR", gender: "female", description: "French"),
            SpeechifyVoice(id: "de-DE-1", name: "Hans", language: "de-DE", gender: "male", description: "German"),
            SpeechifyVoice(id: "it-IT-1", name: "Giulia", language: "it-IT", gender: "female", description: "Italian")
        ]
    }
}

// MARK: - Speechify Voice Model

struct SpeechifyVoice: Codable, Identifiable {
    let id: String
    let name: String
    let language: String
    let gender: String?
    let description: String?

    var languageDisplayName: String {
        Locale.current.localizedString(forIdentifier: language) ?? language
    }

    enum CodingKeys: String, CodingKey {
        case id
        case name = "display_name"
        case language = "locale"
        case gender
        case description
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.id = try container.decode(String.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        self.language = try container.decode(String.self, forKey: .language)
        self.gender = try container.decodeIfPresent(String.self, forKey: .gender)
        self.description = try container.decodeIfPresent(String.self, forKey: .description)
    }
    
    // Manual initializer for fallback voices
    init(id: String, name: String, language: String, gender: String?, description: String?) {
        self.id = id
        self.name = name
        self.language = language
        self.gender = gender
        self.description = description
    }
}
