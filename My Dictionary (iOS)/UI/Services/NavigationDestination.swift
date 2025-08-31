//
//  NavigationDestination.swift
//  My Dictionary
//
//  Created by Alexander Riakhin on 8/1/25.
//

import Foundation

enum NavigationDestination: Hashable {
    // MARK: - Word-related destinations
    case addWord(String, Bool)
    case wordDetails(CDWord)
    case wordMeaningsList(CDWord)
    case addExistingWordToShared(CDWord)
    
    // MARK: - Shared word destinations
    case sharedWordDetails(SharedWord, dictionaryId: String)

    // MARK: - Quiz-related destinations
    case spellingQuiz(QuizPreset)
    case chooseDefinitionQuiz(QuizPreset)
    case sentenceWritingQuiz(QuizPreset)
    case contextMultipleChoiceQuiz(QuizPreset)
    case fillInTheBlankQuiz(QuizPreset)

    // MARK: - Analytics destinations
    case quizResultsList

    // MARK: - Shared dictionary destinations
    case sharedDictionaryWords(SharedDictionary)
    case sharedDictionaryDetails(SharedDictionary)
    case sharedDictionariesList
    case sharedWordDifficultyStats(word: SharedWord)

    // MARK: - Settings destinations
    case aboutApp
    case tagManagement
    case authentication
    case profile
    case ttsDashboard
}
