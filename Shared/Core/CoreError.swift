//
//  CoreError.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import Foundation

enum CoreError: Error {
    case networkError(NetworkError)
    case storageError(StorageError)
    case validationError(ValidationError)
    case internalError(InternalError)
    case analyticsError(AnalyticsError)
    case translationError(TranslationError)
    case unknownError

    // Nested enum for Network Errors
    enum NetworkError: Error {
        case timeout
        case serverUnreachable
        case invalidResponse(statusCode: Int? = nil)
        case noInternetConnection
        case missingAPIKey
        case decodingError
        case invalidURL
        case noData

        var description: String {
            switch self {
            case .timeout: "Timeout"
            case .serverUnreachable: "Server unreachable"
            case .invalidResponse(let code): "Invalid response: \(code ?? 0)"
            case .noInternetConnection: "No internet connection"
            case .missingAPIKey: "Missing API key"
            case .decodingError: "Decoding error"
            case .invalidURL: "Invalid URL"
            case .noData: "No data"
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
        case updatingWordExamplesFailed
        case removingWordFailed
        case savingWordFailed
        case updatingIdiomExamplesFailed
        case removingIdiomFailed
        case savingIdiomFailed
        case inputIsNotAWord
        case inputCannotBeEmpty
        case deviceMutedOrVolumeTooLow
        case cannotPlayAudio
        case cannotSetupAudioSession
        case exportFailed
        case importFailed
        case cannotAccessSecurityScopedResource
        case tagAlreadyExists
        case tagAlreadyAssigned
        case tagNotAssigned
        case maxTagsReached

        var description: String {
            switch self {
            case .updatingWordExamplesFailed:
                return "Error updating word examples"
            case .removingWordFailed:
                return "Error removing word"
            case .savingWordFailed:
                return "Error saving word"
            case .updatingIdiomExamplesFailed:
                return "Error updating idiom examples"
            case .removingIdiomFailed:
                return "Error removing idiom"
            case .savingIdiomFailed:
                return "Error saving idiom"
            case .inputIsNotAWord:
                return "Input is not a word"
            case .inputCannotBeEmpty:
                return "Input cannot be empty"
            case .deviceMutedOrVolumeTooLow:
                return "Device muted or volume too low"
            case .cannotPlayAudio:
                return "Cannot play audio"
            case .cannotSetupAudioSession:
                return "Cannot setup audio session"
            case .exportFailed:
                return "Export failed"
            case .importFailed:
                return "Import failed"
            case .cannotAccessSecurityScopedResource:
                return "Cannot access security scoped resource"
            case .tagAlreadyExists:
                return "Tag already exists"
            case .tagAlreadyAssigned:
                return "Tag is already assigned to this word"
            case .tagNotAssigned:
                return "Tag is not assigned to this word"
            case .maxTagsReached:
                return "Maximum of 5 tags per word reached"
            }
        }
    }
    
    enum AnalyticsError: Error {
        case wordProgressUpdateFailed
        case wordDifficultyUpdateFailed
        case quizSessionSaveFailed
        case userStatsUpdateFailed
        case invalidWordId
        case wordNotFound
        case progressCalculationFailed
        
        var description: String {
            switch self {
            case .wordProgressUpdateFailed:
                return "Failed to update word progress"
            case .wordDifficultyUpdateFailed:
                return "Failed to update word difficulty level"
            case .quizSessionSaveFailed:
                return "Failed to save quiz session"
            case .userStatsUpdateFailed:
                return "Failed to update user statistics"
            case .invalidWordId:
                return "Invalid word ID"
            case .wordNotFound:
                return "Word not found"
            case .progressCalculationFailed:
                return "Failed to calculate progress"
            }
        }
    }

    enum TranslationError: Error, LocalizedError {
        case invalidURL
        case networkError
        case invalidResponse
        case translationFailed

        var description: String {
            switch self {
            case .invalidURL:
                return "Invalid translation URL"
            case .networkError:
                return "Network error during translation"
            case .invalidResponse:
                return "Invalid response from translation service"
            case .translationFailed:
                return "Translation failed"
            }
        }
    }

    var description: String {
        switch self {
        case .networkError(let error): error.description
        case .storageError(let error): error.description
        case .validationError(let error): error.description
        case .internalError(let error): error.description
        case .analyticsError(let error): error.description
        case .translationError(let error): error.description
        case .unknownError: "Unknown error"
        }
    }
}
