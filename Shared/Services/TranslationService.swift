//
//  TranslationService.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/9/25.
//

import Foundation

struct TranslationResponse {
    let text: String
    let languageCode: String
}

protocol TranslationService {
    func translateToEnglish(_ word: String) async throws(CoreError) -> TranslationResponse
    func translateFromLanguage(_ word: String, from languageCode: String) async throws(CoreError) -> TranslationResponse
    func translateDefinition(_ definition: String, to languageCode: String) async throws(CoreError) -> String
}

final class GoogleTranslateService: TranslationService {

    static let shared: TranslationService = GoogleTranslateService()

    private let baseURL = "https://translate.googleapis.com/translate_a/single"

    func translateToEnglish(_ word: String) async throws(CoreError) -> TranslationResponse {
        return try await translateFromLanguage(word, from: "auto")
    }
    
    func translateFromLanguage(_ word: String, from languageCode: String) async throws(CoreError) -> TranslationResponse {
        var components = URLComponents(string: baseURL)
        components?.queryItems = [
            URLQueryItem(name: "client", value: "gtx"),
            URLQueryItem(name: "sl", value: languageCode),
            URLQueryItem(name: "tl", value: "en"),
            URLQueryItem(name: "dt", value: "t"),
            URLQueryItem(name: "q", value: word)
        ]

        guard let url = components?.url else {
            throw .translationError(.invalidURL)
        }
        
        guard let (data, response) = try? await URLSession.shared.data(from: url) else {
            throw .translationError(.networkError)
        }

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw .translationError(.networkError)
        }
        
        let translationResponse = try parseTranslationResponse(data)
        return translationResponse
    }
    
    func translateDefinition(_ definition: String, to languageCode: String) async throws(CoreError) -> String {
        var components = URLComponents(string: baseURL)
        components?.queryItems = [
            URLQueryItem(name: "client", value: "gtx"),
            URLQueryItem(name: "sl", value: "en"),
            URLQueryItem(name: "tl", value: languageCode),
            URLQueryItem(name: "dt", value: "t"),
            URLQueryItem(name: "q", value: definition)
        ]

        guard let url = components?.url else {
            throw .translationError(.invalidURL)
        }
        
        guard let (data, response) = try? await URLSession.shared.data(from: url) else {
            throw .translationError(.invalidResponse)
        }

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw .translationError(.networkError)
        }
        
        let translatedText = try parseDefinitionTranslationResponse(data)
        return translatedText
    }
    
    private func parseTranslationResponse(_ data: Data) throws(CoreError) -> TranslationResponse {
        if let jsonArray = try? JSONSerialization.jsonObject(with: data) as? [Any],
           let translations = jsonArray[0] as? [[Any]],
           let firstTranslation = translations.first,
           let translated = firstTranslation.first as? String,
           let detectedLanguage = jsonArray[2] as? String {
            debugPrint("Detected language:", detectedLanguage)
            return TranslationResponse(text: translated, languageCode: detectedLanguage)
        }

        throw .translationError(.translationFailed)
    }
    
    private func parseDefinitionTranslationResponse(_ data: Data) throws(CoreError) -> String {
        if let jsonArray = try? JSONSerialization.jsonObject(with: data) as? [Any],
           let translations = jsonArray[0] as? [[Any]],
           let firstTranslation = translations.first,
           let translated = firstTranslation.first as? String {
            return translated
        }

        throw .translationError(.translationFailed)
    }
} 
