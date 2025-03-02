//
//  CoreError.swift
//  PureBite
//
//  Created by Aleksandr Riakhin on 9/28/24.
//

import Foundation

enum CoreError: Error {
    case networkError(NetworkError)
    case storageError(StorageError)
    case validationError(ValidationError)
    case internalError(InternalError)
    case unknownError

    // Nested enum for Network Errors
    enum NetworkError: Error {
        case timeout
        case serverUnreachable
        case invalidResponse(statusCode: Int? = nil)
        case noInternetConnection
        case unauthorized
        case missingAPIKey
        case spoonacularError(Error)
        case decodingError
        case invalidURL

        var description: String {
            switch self {
            case .timeout: "Timeout"
            case .serverUnreachable: "Server unreachable"
            case .invalidResponse(let code): "Invalid response: \(code ?? 0)"
            case .noInternetConnection: "No internet connection"
            case .unauthorized: "Unauthorized"
            case .missingAPIKey: "Missing API key"
            case .spoonacularError(let error): "Spoonacular error: \(error)"
            case .decodingError: "Decoding error"
            case .invalidURL: "Invalid URL"
            }
        }
    }

    // StorageError and ValidationError can follow a similar pattern if needed
    enum StorageError: Error {
        case saveFailed
        case readFailed
        case dataCorrupted

        var description: String {
            switch self {
            case .saveFailed: "Save failed"
            case .readFailed: "Read failed"
            case .dataCorrupted: "Data corrupted"
            }
        }

    }

    enum ValidationError: Error {
        case invalidInput(field: String)
        case missingField(field: String)

        var description: String {
            switch self {
            case .invalidInput(field: let field): "Invalid input for field: \(field)"
            case .missingField(field: let field): "Missing field: \(field)"
            }
        }
    }

    enum InternalError: Error {
        case removingWordExampleFailed
        case savingWordExampleFailed
        case removingWordFailed
        case savingWordFailed
        case removingIdiomExampleFailed
        case savingIdiomExampleFailed
        case removingIdiomFailed
        case savingIdiomFailed

        var description: String {
            switch self {
            case .removingWordExampleFailed:
                return "Error removing word example"
            case .savingWordExampleFailed:
                return "Error saving word example"
            case .removingWordFailed:
                return "Error removing word"
            case .savingWordFailed:
                return "Error saving word"
            case .removingIdiomExampleFailed:
                return "Error removing idiom example"
            case .savingIdiomExampleFailed:
                return "Error saving idiom example"
            case .removingIdiomFailed:
                return "Error removing idiom"
            case .savingIdiomFailed:
                return "Error saving idiom"
            }
        }
    }


    var description: String {
        switch self {
        case .networkError(let error): error.description
        case .storageError(let error): error.description
        case .validationError(let error): error.description
        case .internalError(let error): error.description
        case .unknownError: "Unknown error"
        }
    }
}
