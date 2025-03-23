//
//  AnalyticsEvent.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 2/25/25.
//

import Foundation
import Shared

public enum AnalyticsEvent {
    case appOpened
    case wordsListOpened
    case idiomsListOpened
    case quizzesOpened
    case moreOpened

    case wordsListFilterSelected(filter: String)
    case wordsListSortingSelected(sorting: String)

    case addWordTapped
    case wordFetchedData(word: String)
    case addWordFromSearchTapped(word: String)
    case definitionSelected(word: String, number: Int)
    case wordAdded(word: String)
    case wordOpened(word: String)
    case wordRemoved(word: String)
    case listenToWordTapped
    case listenToDefinitionTapped
    case wordExampleAdded
    case wordExampleRemoved
    case definitionChanged
    case partOfSpeechChanged
    case wordFavoriteTapped(isFavorite: Bool)

    case addIdiomTapped
    case idiomAdded
    case idiomOpened
    case idiomChanged
    case idiomRemoved
    case listenToIdiomTapped
    case idiomFavoriteTapped(isFavorite: Bool)
    case idiomExampleAdded
    case idiomExampleUpdated
    case idiomExampleRemoved

    case spellingQuizOpened
    case spellingQuizAnswerConfirmed(isCorrect: Bool)
    case spellingQuizClosed(wordsPlayed: Int)
    case definitionQuizOpened
    case definitionQuizAnswerSelected(isCorrect: Bool)
    case definitionQuizClosed(wordsPlayed: Int)

    case buyMeACoffeeTapped
    case twitterButtonTapped
    case instagramButtonTapped
    case exportToCSVButtonTapped
    case importFromCSVButtonTapped

    var rawValue: String {
        switch self {
        case .appOpened: "appOpened"
        case .wordsListOpened: "wordsListOpened"
        case .idiomsListOpened: "idiomsListOpened"
        case .quizzesOpened: "quizzesOpened"
        case .moreOpened: "moreOpened"
        case .wordsListFilterSelected: "wordsListFilterSelected"
        case .wordsListSortingSelected: "wordsListSortingSelected"
        case .addWordTapped: "addWordTapped"
        case .wordFetchedData: "wordFetchedData"
        case .addWordFromSearchTapped: "addWordFromSearchTapped"
        case .definitionSelected: "definitionSelected"
        case .wordAdded: "wordAdded"
        case .wordOpened: "wordOpened"
        case .wordRemoved: "wordRemoved"
        case .listenToWordTapped: "listenToWordTapped"
        case .listenToDefinitionTapped: "listenToDefinitionTapped"
        case .wordExampleAdded: "wordExampleAdded"
        case .wordExampleRemoved: "wordExampleRemoved"
        case .definitionChanged: "definitionChanged"
        case .partOfSpeechChanged: "partOfSpeechChanged"
        case .wordFavoriteTapped: "wordFavoriteTapped"
        case .addIdiomTapped: "addIdiomTapped"
        case .idiomAdded: "idiomAdded"
        case .idiomOpened: "idiomOpened"
        case .idiomChanged: "idiomChanged"
        case .idiomRemoved: "idiomRemoved"
        case .listenToIdiomTapped: "listenToIdiomTapped"
        case .idiomFavoriteTapped: "idiomFavoriteTapped"
        case .idiomExampleAdded: "idiomExampleAdded"
        case .idiomExampleUpdated: "idiomExampleUpdated"
        case .idiomExampleRemoved: "idiomExampleRemoved"
        case .spellingQuizOpened: "spellingQuizOpened"
        case .spellingQuizAnswerConfirmed: "spellingQuizAnswerConfirmed"
        case .spellingQuizClosed: "spellingQuizClosed"
        case .definitionQuizOpened: "definitionQuizOpened"
        case .definitionQuizAnswerSelected: "definitionQuizAnswerSelected"
        case .definitionQuizClosed: "definitionQuizClosed"
        case .buyMeACoffeeTapped: "buyMeACoffeeTapped"
        case .twitterButtonTapped: "twitterButtonTapped"
        case .instagramButtonTapped: "instagramButtonTapped"
        case .exportToCSVButtonTapped: "exportToCSVButtonTapped"
        case .importFromCSVButtonTapped: "importFromCSVButtonTapped"
        }
    }

    var parameters: [String: Any]? {
        switch self {
        case .appOpened:
            ["version": GlobalConstant.currentFullAppVersion]
        case .wordsListFilterSelected(let filter):
            ["filter": filter]
        case .wordsListSortingSelected(let sorting):
            ["sorting": sorting]
        case .wordFetchedData(let word):
            ["word": word]
        case .addWordFromSearchTapped(let word):
            ["word": word]
        case .definitionSelected(let word, let number):
            ["word": word, "number": number]
        case .wordAdded(let word):
            ["word": word]
        case .wordOpened(let word):
            ["word": word]
        case .wordRemoved(let word):
            ["word": word]
        case .wordFavoriteTapped(let isFavorite):
            ["isFavorite": isFavorite]
        case .idiomFavoriteTapped(let isFavorite):
            ["isFavorite": isFavorite]
        case .spellingQuizAnswerConfirmed(let isCorrect):
            ["isCorrect": isCorrect]
        case .spellingQuizClosed(let wordsPlayed):
            ["wordsPlayed": wordsPlayed]
        case .definitionQuizAnswerSelected(let isCorrect):
            ["isCorrect": isCorrect]
        case .definitionQuizClosed(let wordsPlayed):
            ["wordsPlayed": wordsPlayed]
        default:
            nil
        }
    }
}
