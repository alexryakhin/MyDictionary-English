//
//  CloudFunctionsService.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/9/25.
//

import Foundation
import FirebaseAuth

final class CloudFunctionsService {

    // MARK: - Singleton

    static let shared = CloudFunctionsService()

    private init() {}

    // MARK: - Function Endpoints

    enum Function: String, CaseIterable {
        case checkNicknameAvailability = "checkNicknameAvailability"
        case searchUser = "searchUser"
        case synthesizeSpeech = "synthesizeSpeech"
        case openAIProxy = "openAIProxy"
        case sendNotification = "sendNotification"

        var url: String {
            return "https://europe-west3-my-dictionary-english.cloudfunctions.net/\(rawValue)"
        }
    }

    // MARK: - Generic Request Method

    private func makeRequest<T: Codable>(
        to function: Function,
        method: HTTPMethod = .GET,
        body: [String: Any]? = nil,
        responseType: T.Type
    ) async throws -> T {

        guard let userId = Auth.auth().currentUser?.uid else {
            throw CloudFunctionsError.userNotAuthenticated
        }

        let url = URL(string: function.url)!
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Add user ID to all requests for security
        var requestBody = body ?? [:]
        requestBody["userId"] = userId

        if !requestBody.isEmpty {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        }

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw CloudFunctionsError.invalidResponse
        }

        // Handle HTTP errors
        switch httpResponse.statusCode {
        case 200...299:
            break
        case 400:
            throw CloudFunctionsError.badRequest
        case 401:
            throw CloudFunctionsError.unauthorized
        case 403:
            throw CloudFunctionsError.forbidden
        case 429:
            throw CloudFunctionsError.rateLimitExceeded
        case 500...599:
            throw CloudFunctionsError.serverError
        default:
            throw CloudFunctionsError.httpError(httpResponse.statusCode)
        }

        // Parse response
        do {
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

            if let success = json?["success"] as? Bool, !success {
                let errorMessage = json?["error"] as? String ?? "Unknown error"
                throw CloudFunctionsError.apiError(errorMessage)
            }

            let decoder = JSONDecoder()
            return try decoder.decode(T.self, from: data)
        } catch {
            if error is CloudFunctionsError {
                throw error
            }
            throw CloudFunctionsError.parsingError(error.localizedDescription)
        }
    }

    // MARK: - Nickname Management

    struct NicknameAvailabilityResponse: Codable {
        let success: Bool
        let isAvailable: Bool
        let nickname: String
    }

    func checkNicknameAvailability(_ nickname: String) async throws -> Bool {
        let response: NicknameAvailabilityResponse = try await makeRequest(
            to: .checkNicknameAvailability,
            method: .POST,
            body: ["nickname": nickname],
            responseType: NicknameAvailabilityResponse.self
        )
        return response.isAvailable
    }

    // MARK: - User Search

    struct UserSearchResponse: Codable {
        let success: Bool
        let user: UserInfo?
    }

    func searchUserByEmail(_ email: String) async throws -> UserInfo? {
        let response: UserSearchResponse = try await makeRequest(
            to: .searchUser,
            method: .POST,
            body: [
                "query": email,
                "searchType": "email"
            ],
            responseType: UserSearchResponse.self
        )
        return response.user
    }

    func searchUserByNickname(_ nickname: String) async throws -> UserInfo? {
        let response: UserSearchResponse = try await makeRequest(
            to: .searchUser,
            method: .POST,
            body: [
                "query": nickname,
                "searchType": "nickname"
            ],
            responseType: UserSearchResponse.self
        )
        return response.user
    }

    // MARK: - Speechify Integration

    struct SpeechifySynthesizeResponse: Codable {
        let success: Bool
        let audioData: String
        let format: String
        let voice: String?
        let billableCharacters: Int?
        let textLength: Int
    }

    func synthesizeSpeech(
        text: String,
        voice: String?,
        language: String,
        model: String,
        audioFormat: String
    ) async throws -> SpeechifySynthesizeResponse {
        return try await makeRequest(
            to: .synthesizeSpeech,
            method: .POST,
            body: [
                "text": text,
                "voice": voice ?? "en-US-1",
                "language": language,
                "model": model,
                "audioFormat": audioFormat
            ],
            responseType: SpeechifySynthesizeResponse.self
        )
    }

    // MARK: - OpenAI Integration
    
    struct FirebaseOpenAIResponse: Codable {
        let success: Bool
        let data: String
        let usage: OpenAIUsage?
    }
    
    struct OpenAIUsage: Codable {
        let promptTokens: Int
        let completionTokens: Int
        let totalTokens: Int
    }
    
    func openAIProxy(
        word: String,
        maxDefinitions: Int,
        inputLanguage: String,
        userLanguage: String,
        sentence: String? = nil,
        sentences: [(sentence: String, targetWord: String)]? = nil,
        contextQuestions: Bool = false,
        fillInTheBlank: Bool = false,
        singleContextQuestion: Bool = false,
        singleFillInTheBlank: Bool = false,
        wordLanguage: String? = nil,
        words: [String]? = nil
    ) async throws -> FirebaseOpenAIResponse {
        var body: [String: Any] = [
            "word": word,
            "maxDefinitions": maxDefinitions,
            "inputLanguage": inputLanguage,
            "userLanguage": userLanguage
        ]
        
        // Add optional parameters for quiz functionality
        if let sentences = sentences {
            body["sentences"] = sentences
        } else if let sentence = sentence {
            body["sentence"] = sentence
        }
        if contextQuestions {
            body["contextQuestions"] = true
        }
        if let words = words {
            body["words"] = words
        }
        if fillInTheBlank {
            body["fillInTheBlank"] = true
        }
        if singleContextQuestion {
            body["singleContextQuestion"] = true
        }
        if singleFillInTheBlank {
            body["singleFillInTheBlank"] = true
        }
        if let wordLanguage = wordLanguage {
            body["wordLanguage"] = wordLanguage
        }
        
        return try await makeRequest(
            to: .openAIProxy,
            method: .POST,
            body: body,
            responseType: FirebaseOpenAIResponse.self
        )
    }

    // MARK: - Notifications

    struct NotificationResponse: Codable {
        let success: Bool
        let messageId: String?
    }

    func sendNotification(
        token: String,
        title: String,
        body: String,
        data: [String: String]?
    ) async throws -> NotificationResponse {
        return try await makeRequest(
            to: .sendNotification,
            method: .POST,
            body: [
                "token": token,
                "title": title,
                "body": body,
                "data": data ?? [:]
            ],
            responseType: NotificationResponse.self
        )
    }
}

// MARK: - Supporting Types

enum HTTPMethod: String {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case DELETE = "DELETE"
}

enum CloudFunctionsError: Error, LocalizedError {
    case userNotAuthenticated
    case invalidResponse
    case badRequest
    case unauthorized
    case forbidden
    case rateLimitExceeded
    case serverError
    case httpError(Int)
    case apiError(String)
    case parsingError(String)

    var errorDescription: String? {
        switch self {
        case .userNotAuthenticated:
            return "User not authenticated"
        case .invalidResponse:
            return "Invalid response from server"
        case .badRequest:
            return "Bad request"
        case .unauthorized:
            return "Unauthorized"
        case .forbidden:
            return "Forbidden"
        case .rateLimitExceeded:
            return "Rate limit exceeded"
        case .serverError:
            return "Server error"
        case .httpError(let code):
            return "HTTP error: \(code)"
        case .apiError(let message):
            return message
        case .parsingError(let message):
            return "Parsing error: \(message)"
        }
    }
}
