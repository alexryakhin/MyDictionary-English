//
//  AnalyticsEvent.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 2/25/25.
//

import Foundation

enum AnalyticsEvent: String {
    case appOpened
    case wordsListOpened
    case idiomsListOpened
    case quizzesOpened
    case analyticsOpened
    case moreOpened
    case aboutAppScreenOpened

    case wordsListFilterSelected
    case wordsListSortingSelected

    case addWordTapped
    case addWordOpened
    case closeAddWordTapped
    case saveWordTapped
    case wordFetchedData
    case addWordFromSearchTapped
    case definitionSelected
    case wordAdded
    case wordOpened
    case wordPlayed
    case wordRemoved
    case wordRemovingCanceled
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
    case removeWordMenuButtonTapped
    case wordPhoneticsChanged

    case idiomsListFilterSelected
    case idiomsListSortingSelected

    case addIdiomTapped
    case addIdiomTappedFromSearch
    case addIdiomOpened
    case closeAddIdiomTapped
    case saveIdiomTapped
    case idiomAdded
    case idiomOpened
    case idiomPlayed
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
    case idiomExampleChangingCanceled
    case idiomAddExampleTapped
    case removeIdiomMenuButtonTapped
    case idiomDeleteSwipeAction

    case spellingQuizOpened
    case spellingQuizAnswerConfirmed
    case spellingQuizWordSkipped
    case spellingQuizRestarted
    case definitionQuizOpened
    case definitionQuizAnswerSelected
    case definitionQuizWordSkipped
    case definitionQuizRestarted

    case buyMeACoffeeTapped
    case twitterButtonTapped
    case instagramButtonTapped
    case exportToCSVButtonTapped
    case importFromCSVButtonTapped
    case languageAccentChanged
    case aboutAppTapped
    case requestReviewTapped

    var parameters: [String: Any]? {
        switch self {
        case .appOpened:
            ["version": GlobalConstant.currentFullAppVersion]
        default:
            nil
        }
    }
}
