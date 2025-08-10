//
//  NavigationDestination.swift
//  My Dictionary
//
//  Created by Alexander Riakhin on 8/1/25.
//

import Foundation

enum NavigationDestination: Hashable {
    // MARK: - Word-related destinations
    case addWord
    case wordDetails(WordDetailsContentView.Config)
    case addExistingWordToShared(CDWord)

    // MARK: - Idiom-related destinations
    case addIdiom
    case idiomDetails(CDIdiom)
    
    // MARK: - Quiz-related destinations
    case spellingQuiz(wordCount: Int, hardWordsOnly: Bool)
    case chooseDefinitionQuiz(wordCount: Int, hardWordsOnly: Bool)
    case quizResultsDetail
    
    // MARK: - Shared dictionary destinations
    case addSharedDictionary
    case sharedDictionaryWords(SharedDictionary)
    case sharedDictionaryDetails(SharedDictionary)
    case sharedDictionariesList
    
    // MARK: - Settings destinations
    case aboutApp
    case tagManagement
    case authentication
}
