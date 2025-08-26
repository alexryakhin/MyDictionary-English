//
//  CoreError.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import Foundation

enum CoreError: Error, LocalizedError {
    case networkError(NetworkError)
    case storageError(StorageError)
    case validationError(ValidationError)
    case internalError(InternalError)
    case analyticsError(AnalyticsError)
    case translationError(TranslationError)
    case unknownError

    // Nested enum for Network Errors
    enum NetworkError: Error, LocalizedError {
        case timeout
        case serverUnreachable
        case invalidResponse(statusCode: Int? = nil)
        case noInternetConnection
        case missingAPIKey
        case decodingError
        case invalidURL
        case noData


        var errorDescription: String? {
            switch self {
            case .timeout: Loc.Errors.networkTimeout
            case .serverUnreachable: Loc.Errors.serverUnreachable
            case .invalidResponse(let code): Loc.Errors.invalidResponse
            case .noInternetConnection: Loc.Errors.noInternetConnection
            case .missingAPIKey: Loc.Errors.missingApiKey
            case .decodingError: Loc.Errors.decodingError
            case .invalidURL: Loc.Errors.invalidUrl
            case .noData: Loc.Errors.noData
            }
        }
    }

    // StorageError and ValidationError can follow a similar pattern if needed
    enum StorageError: Error, LocalizedError {
        case saveFailed
        case readFailed
        case dataCorrupted

        var errorDescription: String? {
            switch self {
            case .saveFailed: Loc.Errors.saveFailed
            case .readFailed: Loc.Errors.readFailed
            case .dataCorrupted: Loc.Errors.dataCorrupted
            }
        }
    }

    enum ValidationError: Error, LocalizedError {
        case invalidInput(field: String)
        case missingField(field: String)

        var errorDescription: String? {
            switch self {
            case .invalidInput: Loc.Errors.invalidInput
            case .missingField: Loc.Errors.missingField
            }
        }
    }

    enum InternalError: Error, LocalizedError {
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
        case exportLimitExceeded
        case tagAlreadyExists
        case tagAlreadyAssigned
        case tagNotAssigned
        case maxTagsReached
        case authenticationRequired
        case noActiveSubscription

        var errorDescription: String? {
            switch self {
            case .updatingWordExamplesFailed:
                return Loc.Errors.errorUpdatingWordExamples
            case .removingWordFailed:
                return Loc.Errors.errorRemovingWord
            case .savingWordFailed:
                return Loc.Errors.errorSavingWord
            case .updatingIdiomExamplesFailed:
                return Loc.Errors.errorUpdatingIdiomExamples
            case .removingIdiomFailed:
                return Loc.Errors.errorRemovingIdiom
            case .savingIdiomFailed:
                return Loc.Errors.errorSavingIdiom
            case .inputIsNotAWord:
                return Loc.Errors.inputNotWord
            case .inputCannotBeEmpty:
                return Loc.Errors.inputCannotBeEmpty
            case .deviceMutedOrVolumeTooLow:
                return Loc.Errors.deviceMutedOrVolumeLow
            case .cannotPlayAudio:
                return Loc.Errors.cannotPlayAudio
            case .cannotSetupAudioSession:
                return Loc.Errors.cannotSetupAudioSession
            case .exportFailed:
                return Loc.Errors.exportFailed
            case .importFailed:
                return Loc.Errors.importFailed
            case .cannotAccessSecurityScopedResource:
                return Loc.Errors.cannotAccessSecurityScopedResource
            case .exportLimitExceeded:
                return Loc.Errors.exportLimitExceeded
            case .tagAlreadyExists:
                return Loc.Errors.tagAlreadyExists
            case .tagAlreadyAssigned:
                return Loc.Errors.tagAlreadyAssigned
            case .tagNotAssigned:
                return Loc.Errors.tagNotAssigned
            case .maxTagsReached:
                return Loc.Errors.maxTagsReached
            case .authenticationRequired:
                return Loc.Errors.authenticationRequired
            case .noActiveSubscription:
                return Loc.Errors.noActiveSubscriptionsFound
            }
        }
    }
    
    enum AnalyticsError: Error, LocalizedError {
        case wordProgressUpdateFailed
        case wordDifficultyUpdateFailed
        case quizSessionSaveFailed
        case userStatsUpdateFailed
        case invalidWordId
        case wordNotFound
        case progressCalculationFailed
        
        var errorDescription: String? {
            switch self {
            case .wordProgressUpdateFailed:
                return Loc.Errors.failedToUpdateWordProgress
            case .wordDifficultyUpdateFailed:
                return Loc.Errors.failedToUpdateWordDifficultyLevel
            case .quizSessionSaveFailed:
                return Loc.Errors.failedToSaveQuizSession
            case .userStatsUpdateFailed:
                return Loc.Errors.failedToUpdateUserStatistics
            case .invalidWordId:
                return Loc.Errors.invalidWordId
            case .wordNotFound:
                return Loc.Errors.wordNotFound
            case .progressCalculationFailed:
                return Loc.Errors.failedToCalculateProgress
            }
        }
    }

    enum TranslationError: Error, LocalizedError {
        case invalidURL
        case networkError
        case invalidResponse
        case translationFailed

        var errorDescription: String? {
            switch self {
            case .invalidURL:
                return Loc.Errors.invalidTranslationUrl
            case .networkError:
                return Loc.Errors.networkErrorDuringTranslation
            case .invalidResponse:
                return Loc.Errors.invalidResponseFromTranslationService
            case .translationFailed:
                return Loc.Errors.translationFailed
            }
        }
    }

    var errorDescription: String? {
        switch self {
        case .networkError(let error): error.errorDescription
        case .storageError(let error): error.errorDescription
        case .validationError(let error): error.errorDescription
        case .internalError(let error): error.errorDescription
        case .analyticsError(let error): error.errorDescription
        case .translationError(let error): error.errorDescription
        case .unknownError: Loc.Errors.unknownError
        }
    }
}
