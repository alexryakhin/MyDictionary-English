//
//  QuizzesListViewModel.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import Foundation
import Combine
import SwiftUI

final class QuizzesListViewModel: BaseViewModel {

    enum Output {
        case showSpellingQuiz(wordCount: Int, hardWordsOnly: Bool)
        case showChooseDefinitionQuiz(wordCount: Int, hardWordsOnly: Bool)
        case showSharedDictionary(SharedDictionary)
    }

    enum Input {
        case dictionarySelected(QuizDictionary)
    }

    var output = PassthroughSubject<Output, Never>()

    @Published var showingHardWordsOnly = false
    @Published var selectedDictionary: QuizDictionary = .privateDictionary

    private let quizWordsProvider: QuizWordsProvider = .shared
    private var cancellables: Set<AnyCancellable> = []

    override init() {
        super.init()
        setupBindings()
    }

    func handle(_ input: Input) {
        switch input {
        case .dictionarySelected(let dictionary):
            selectedDictionary = dictionary
            quizWordsProvider.selectedDictionary = dictionary
            
            // If it's a shared dictionary, ensure words are loaded
            if case .sharedDictionary(let sharedDictionary) = dictionary {
                print("🔄 [QuizzesListViewModel] Shared dictionary selected: \(sharedDictionary.name)")
                quizWordsProvider.loadWordsForSharedDictionary(sharedDictionary)
            }
        }
    }
    
    // MARK: - Computed Properties
    
    var availableDictionaries: [QuizDictionary] {
        return quizWordsProvider.availableDictionaries
    }
    
    var words: [any QuizWord] {
        return quizWordsProvider.availableWords
    }
    
    var filteredWords: [any QuizWord] {
        if showingHardWordsOnly {
            return words.filter { $0.difficultyLevel == .needsReview }
        }
        return words
    }
    
    var hasHardWords: Bool {
        return words.filter { $0.difficultyLevel == .needsReview }.count > 10
    }
    
    var hasEnoughWords: Bool {
        // For shared dictionaries, check if words are loaded and if there are enough
        if case .sharedDictionary(let dictionary) = selectedDictionary {
            let wordCount = quizWordsProvider.getTotalWordsCount()
            let requiredCount = showingHardWordsOnly ? 1 : 10
            return wordCount >= requiredCount
        }
        // For private dictionary, use the existing logic
        return quizWordsProvider.hasEnoughWords(wordCount: 10, hardWordsOnly: showingHardWordsOnly)
    }
    
    var insufficientWordsMessage: String {
        if case .sharedDictionary(let dictionary) = selectedDictionary {
            let totalWords = quizWordsProvider.getTotalWordsCount()
            if showingHardWordsOnly {
                let hardWordsCount = quizWordsProvider.getHardWordsCount()
                return "The shared dictionary '\(dictionary.name)' needs at least 1 hard word to practice in hard words mode. It currently has \(hardWordsCount) hard words."
            } else {
                return "The shared dictionary '\(dictionary.name)' needs at least 10 words to start quizzes. It currently has \(totalWords) words."
            }
        } else {
            // Private dictionary message
            if showingHardWordsOnly {
                let hardWordsCount = quizWordsProvider.getHardWordsCount()
                return "You need at least 1 hard word to practice in hard words mode. You currently have \(hardWordsCount) hard words."
            } else {
                let totalWords = quizWordsProvider.getTotalWordsCount()
                return "You need at least 10 words to start quizzes. You currently have \(totalWords) words."
            }
        }
    }

    /// Fetches latest data from Core Data
    private func setupBindings() {
        // Listen to quiz words provider changes
        quizWordsProvider.$selectedDictionary
            .receive(on: RunLoop.main)
            .sink { [weak self] dictionary in
                self?.selectedDictionary = dictionary
            }
            .store(in: &cancellables)
        
        // Listen to available words changes (important for shared dictionaries)
        quizWordsProvider.$availableWords
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                // UI will automatically update when words change
                // No need for explicit logging here to avoid console spam
            }
            .store(in: &cancellables)
    }
}
