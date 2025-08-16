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
            case .timeout: Loc.networkTimeout.localized
            case .serverUnreachable: Loc.serverUnreachable.localized
            case .invalidResponse(let code): Loc.invalidResponse.localized(code ?? 0)
            case .noInternetConnection: Loc.noInternetConnection.localized
            case .missingAPIKey: Loc.missingAPIKey.localized
            case .decodingError: Loc.decodingError.localized
            case .invalidURL: Loc.invalidURL.localized
            case .noData: Loc.noData.localized
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
            case .saveFailed: Loc.saveFailed.localized
            case .readFailed: Loc.readFailed.localized
            case .dataCorrupted: Loc.dataCorrupted.localized
            }
        }
    }

    enum ValidationError: Error, LocalizedError {
        case invalidInput(field: String)
        case missingField(field: String)

        var errorDescription: String? {
            switch self {
            case .invalidInput(field: let field): Loc.invalidInput.localized(field)
            case .missingField(field: let field): Loc.missingField.localized(field)
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
                return Loc.errorUpdatingWordExamples.localized
            case .removingWordFailed:
                return Loc.errorRemovingWord.localized
            case .savingWordFailed:
                return Loc.errorSavingWord.localized
            case .updatingIdiomExamplesFailed:
                return Loc.errorUpdatingIdiomExamples.localized
            case .removingIdiomFailed:
                return Loc.errorRemovingIdiom.localized
            case .savingIdiomFailed:
                return Loc.errorSavingIdiom.localized
            case .inputIsNotAWord:
                return Loc.inputNotWord.localized
            case .inputCannotBeEmpty:
                return Loc.inputCannotBeEmpty.localized
            case .deviceMutedOrVolumeTooLow:
                return Loc.deviceMutedOrVolumeLow.localized
            case .cannotPlayAudio:
                return Loc.cannotPlayAudio.localized
            case .cannotSetupAudioSession:
                return Loc.cannotSetupAudioSession.localized
            case .exportFailed:
                return Loc.exportFailed.localized
            case .importFailed:
                return Loc.importFailed.localized
            case .cannotAccessSecurityScopedResource:
                return Loc.cannotAccessSecurityScopedResource.localized
            case .exportLimitExceeded:
                return Loc.exportLimitExceeded.localized
            case .tagAlreadyExists:
                return Loc.tagAlreadyExists.localized
            case .tagAlreadyAssigned:
                return Loc.tagAlreadyAssigned.localized
            case .tagNotAssigned:
                return Loc.tagNotAssigned.localized
            case .maxTagsReached:
                return Loc.maxTagsReached.localized
            case .authenticationRequired:
                return Loc.authenticationRequired.localized
            case .noActiveSubscription:
                return Loc.noActiveSubscriptionsFound.localized
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
                return Loc.failedToUpdateWordProgress.localized
            case .wordDifficultyUpdateFailed:
                return Loc.failedToUpdateWordDifficultyLevel.localized
            case .quizSessionSaveFailed:
                return Loc.failedToSaveQuizSession.localized
            case .userStatsUpdateFailed:
                return Loc.failedToUpdateUserStatistics.localized
            case .invalidWordId:
                return Loc.invalidWordId.localized
            case .wordNotFound:
                return Loc.wordNotFound.localized
            case .progressCalculationFailed:
                return Loc.failedToCalculateProgress.localized
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
                return Loc.invalidTranslationUrl.localized
            case .networkError:
                return Loc.networkErrorDuringTranslation.localized
            case .invalidResponse:
                return Loc.invalidResponseFromTranslationService.localized
            case .translationFailed:
                return Loc.translationFailed.localized
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
        case .unknownError: Loc.unknownError.localized
        }
    }
}
