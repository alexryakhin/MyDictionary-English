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
    case settingsOpened
    case aboutAppScreenOpened
    case quizResultsDetailOpened

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
    case wordAddedToSharedDictionary
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
    case wordDifficultyChanged
    case meaningRemovingCanceled
    case meaningPlayed
    case meaningUpdated
    case meaningRemoved

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
    
    // Rating Banner Events
    case ratingBannerTapped
    case ratingBannerDismissed
    
    // Coffee Banner Events
    case coffeeBannerTapped
    case coffeeBannerDismissed
    case spellingQuizRestarted
    case definitionQuizOpened
    case definitionQuizAnswerSelected
    case definitionQuizWordSkipped
    case definitionQuizRestarted

    case tagCreated
    case tagUpdated
    case tagDeleted
    case tagAddedToWord
    case tagRemovedFromWord
    case tagAddedToIdiom
    case tagRemovedFromIdiom
    case tagManagementOpened

    case buyMeACoffeeTapped
    case twitterButtonTapped
    case instagramButtonTapped
    case exportToCSVButtonTapped
    case importFromCSVButtonTapped
    case languageAccentChanged
    case aboutAppTapped
    case requestReviewTapped
    
    // Translation Events
    case translationRequested
    case translationCompleted
    case translationFailed
    case definitionTranslationEnabled
    case definitionTranslationDisabled

    // Authentication Events
    case signInWithGoogleTapped
    case signInWithAppleTapped
    case signInAnonymouslyTapped
    case signOutTapped
    case accountLinkingOpened
    case googleAccountLinked
    case appleAccountLinked
    case accountLinkingFailed
    
    // Subscription Events
    case subscriptionScreenOpened
    case subscriptionPurchased
    case subscriptionRestored
    case subscriptionCancelled
    case subscriptionError
    case paywallPresented
    case subscriptionOwnershipMismatch
    
    // API Selection Events
    case wordnikAPISelected
    case dictionaryAPISelected
    case wordnikAPIFailed
    case dictionaryAPIFailed
    
    // Collaborative Features Events
    case sharedWordLiked
    case sharedWordUnliked
    case sharedWordDifficultyUpdated
    case sharedWordStatsViewed

    var parameters: [String: Any]? {
        switch self {
        case .appOpened:
            ["version": GlobalConstant.currentFullAppVersion]
        default:
            nil
        }
    }
}
