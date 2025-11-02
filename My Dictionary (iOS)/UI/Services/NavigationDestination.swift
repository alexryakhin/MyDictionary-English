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
    case storyLab(StoryLabConfig)

    // MARK: - Analytics destinations
    case quizResultsList
    case allQuizActivity

    // MARK: - Shared dictionary destinations
    case sharedDictionaryWords(SharedDictionary)
    case sharedDictionaryDetails(SharedDictionary)
    case sharedDictionariesList
    case sharedWordDifficultyStats(word: SharedWord)

    // MARK: - Word Collections destinations
    case wordCollections
    case wordCollectionDetails(WordCollection)
    
    // MARK: - Settings destinations
    case aboutApp
    case tagManagement
    case authentication
    case profile
    case ttsDashboard
    case deleteWords
    
    // MARK: - Story Lab destinations
    case storyLabHistory
}
