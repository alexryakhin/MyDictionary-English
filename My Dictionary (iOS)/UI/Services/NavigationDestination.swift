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
    case wordDetails(CDWord)
    case addExistingWordToShared(CDWord)
    
    // MARK: - Shared word destinations
    case sharedWordDetails(SharedWord, dictionaryId: String)
    
    // MARK: - Idiom-related destinations
    case addIdiom
    case idiomDetails(CDIdiom)
    
    // MARK: - Quiz-related destinations
    case spellingQuiz(wordCount: Int, hardWordsOnly: Bool)
    case chooseDefinitionQuiz(wordCount: Int, hardWordsOnly: Bool)
    case quizResults(QuizResultsView.Model)

    // MARK: - Analytics destinations
    case quizResultsList

    // MARK: - Shared dictionary destinations
    case addSharedDictionary
    case sharedDictionaryWords(SharedDictionary)
    case sharedDictionaryDetails(SharedDictionary)
    case sharedDictionariesList
    case sharedWordDifficultyStats(word: SharedWord)

    // MARK: - Settings destinations
    case aboutApp
    case tagManagement
    case authentication
}
