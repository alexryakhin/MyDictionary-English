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
            case .timeout: Loc.Errors.networkTimeout.localized
            case .serverUnreachable: Loc.Errors.serverUnreachable.localized
            case .invalidResponse(let code): Loc.Errors.invalidResponse.localized(code ?? 0)
            case .noInternetConnection: Loc.Errors.noInternetConnection.localized
            case .missingAPIKey: Loc.Errors.missingAPIKey.localized
            case .decodingError: Loc.Errors.decodingError.localized
            case .invalidURL: Loc.Errors.invalidURL.localized
            case .noData: Loc.Errors.noData.localized
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
            case .saveFailed: Loc.Errors.saveFailed.localized
            case .readFailed: Loc.Errors.readFailed.localized
            case .dataCorrupted: Loc.Errors.dataCorrupted.localized
            }
        }
    }

    enum ValidationError: Error, LocalizedError {
        case invalidInput(field: String)
        case missingField(field: String)

        var errorDescription: String? {
            switch self {
            case .invalidInput(field: let field): Loc.Errors.invalidInput.localized(field)
            case .missingField(field: let field): Loc.Errors.missingField.localized(field)
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
                return Loc.Errors.errorUpdatingWordExamples.localized
            case .removingWordFailed:
                return Loc.Errors.errorRemovingWord.localized
            case .savingWordFailed:
                return Loc.Errors.errorSavingWord.localized
            case .updatingIdiomExamplesFailed:
                return Loc.Errors.errorUpdatingIdiomExamples.localized
            case .removingIdiomFailed:
                return Loc.Errors.errorRemovingIdiom.localized
            case .savingIdiomFailed:
                return Loc.Errors.errorSavingIdiom.localized
            case .inputIsNotAWord:
                return Loc.Errors.inputNotWord.localized
            case .inputCannotBeEmpty:
                return Loc.Errors.inputCannotBeEmpty.localized
            case .deviceMutedOrVolumeTooLow:
                return Loc.Errors.deviceMutedOrVolumeLow.localized
            case .cannotPlayAudio:
                return Loc.Errors.cannotPlayAudio.localized
            case .cannotSetupAudioSession:
                return Loc.Errors.cannotSetupAudioSession.localized
            case .exportFailed:
                return Loc.Errors.exportFailed.localized
            case .importFailed:
                return Loc.Errors.importFailed.localized
            case .cannotAccessSecurityScopedResource:
                return Loc.Errors.cannotAccessSecurityScopedResource.localized
            case .exportLimitExceeded:
                return Loc.Errors.exportLimitExceeded.localized
            case .tagAlreadyExists:
                return Loc.Errors.tagAlreadyExists.localized
            case .tagAlreadyAssigned:
                return Loc.Errors.tagAlreadyAssigned.localized
            case .tagNotAssigned:
                return Loc.Errors.tagNotAssigned.localized
            case .maxTagsReached:
                return Loc.Errors.maxTagsReached.localized
            case .authenticationRequired:
                return Loc.Errors.authenticationRequired.localized
            case .noActiveSubscription:
                return Loc.Errors.noActiveSubscriptionsFound.localized
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
                return Loc.Errors.failedToUpdateWordProgress.localized
            case .wordDifficultyUpdateFailed:
                return Loc.Errors.failedToUpdateWordDifficultyLevel.localized
            case .quizSessionSaveFailed:
                return Loc.Errors.failedToSaveQuizSession.localized
            case .userStatsUpdateFailed:
                return Loc.Errors.failedToUpdateUserStatistics.localized
            case .invalidWordId:
                return Loc.Errors.invalidWordId.localized
            case .wordNotFound:
                return Loc.Errors.wordNotFound.localized
            case .progressCalculationFailed:
                return Loc.Errors.failedToCalculateProgress.localized
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
                return Loc.Errors.invalidTranslationUrl.localized
            case .networkError:
                return Loc.Errors.networkErrorDuringTranslation.localized
            case .invalidResponse:
                return Loc.Errors.invalidResponseFromTranslationService.localized
            case .translationFailed:
                return Loc.Errors.translationFailed.localized
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
        case .unknownError: Loc.Errors.unknownError.localized
        }
    }
}
