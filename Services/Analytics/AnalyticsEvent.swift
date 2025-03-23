//
//  AnalyticsEvent.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 2/25/25.
//

import Foundation
import Shared

public enum AnalyticsEvent: String {
    case appOpened
    case wordsListOpened
    case idiomsListOpened
    case quizzesOpened
    case moreOpened
    case aboutAppScreenOpened

    case wordsListFilterSelected
    case wordsListSortingSelected

    case addWordTapped
    case wordFetchedData
    case addWordFromSearchTapped
    case definitionSelected
    case wordAdded
    case wordOpened
    case wordRemoved
    case wordRemovingCanceled
    case listenToWordTapped
    case listenToDefinitionTapped
    case wordExampleAdded
    case wordExampleUpdated
    case wordExampleRemoved
    case wordExamplePlayed
    case wordExampleChangeButtonTapped
    case wordExampleChanged
    case wordExampleChangingCanceled
    case wordDefinitionChanged
    case wordDefinitionPlayed
    case partOfSpeechChanged
    case wordFavoriteTapped
    case wordAddExampleTapped

    case addIdiomTapped
    case idiomAdded
    case idiomOpened
    case idiomDefinitionChanged
    case idiomDefinitionPlayed
    case idiomChanged
    case idiomRemoved
    case idiomRemovingCanceled
    case listenToIdiomTapped
    case idiomFavoriteTapped
    case idiomExampleAdded
    case idiomExampleUpdated
    case idiomExampleRemoved
    case idiomExamplePlayed
    case idiomExampleChangeButtonTapped
    case idiomExampleChanged
    case idiomExampleChangingCanceled
    case idiomAddExampleTapped

    case spellingQuizOpened
    case spellingQuizAnswerConfirmed
    case spellingQuizClosed
    case definitionQuizOpened
    case definitionQuizAnswerSelected
    case definitionQuizClosed

    case buyMeACoffeeTapped
    case twitterButtonTapped
    case instagramButtonTapped
    case exportToCSVButtonTapped
    case importFromCSVButtonTapped

    var parameters: [String: Any]? {
        switch self {
        case .appOpened:
            ["version": GlobalConstant.currentFullAppVersion]
        default:
            nil
        }
    }
}
