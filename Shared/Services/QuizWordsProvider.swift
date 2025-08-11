//
//  QuizWordsProvider.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import Foundation
import Combine

/// Service that provides words for quizzes from both private and shared dictionaries
final class QuizWordsProvider: ObservableObject {
    static let shared = QuizWordsProvider()
    
    @Published var availableWords: [any QuizWord] = []
    @Published var selectedDictionary: QuizDictionary = .privateDictionary
    @Published var availableDictionaries: [QuizDictionary] = []
    
    private let wordsProvider: WordsProvider = .shared
    private let dictionaryService: DictionaryService = .shared
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        setupBindings()
    }
    
    // MARK: - Public Methods
    
    /// Gets words for a quiz based on the selected dictionary and filters
    /// - Parameters:
    ///   - wordCount: Number of words needed
    ///   - hardWordsOnly: Whether to only include difficult words
    /// - Returns: Array of words for the quiz
    func getWordsForQuiz(wordCount: Int, hardWordsOnly: Bool = false) -> [any QuizWord] {
        let filteredWords = hardWordsOnly
        ? availableWords.filter { $0.difficultyLevel == .needsReview }
        : availableWords

        return Array(filteredWords.shuffled().prefix(wordCount))
    }
    
    /// Checks if there are enough words available for a quiz
    /// - Parameters:
    ///   - wordCount: Number of words needed
    ///   - hardWordsOnly: Whether to only include difficult words
    /// - Returns: Whether enough words are available
    func hasEnoughWords(wordCount: Int, hardWordsOnly: Bool = false) -> Bool {
        let filteredWords = hardWordsOnly
        ? availableWords.filter { $0.difficultyLevel == .needsReview }
        : availableWords

        return filteredWords.count >= wordCount
    }
    
    /// Gets the minimum required words for hard words mode
    /// - Returns: Number of hard words available
    func getHardWordsCount() -> Int {
        return availableWords.filter { $0.difficultyLevel == .needsReview }.count
    }
    
    /// Gets the total number of words available
    /// - Returns: Total number of words
    func getTotalWordsCount() -> Int {
        return availableWords.count
    }
    
    // MARK: - Private Methods
    
    private func setupBindings() {
        // Listen to private words changes
        wordsProvider.$words
            .receive(on: DispatchQueue.main)
            .sink { [weak self] words in
                self?.updateAvailableDictionaries()
                self?.updateAvailableWords()
            }
            .store(in: &cancellables)
        
        // Listen to shared dictionaries changes
        dictionaryService.$sharedDictionaries
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateAvailableDictionaries()
                self?.updateAvailableWords()
            }
            .store(in: &cancellables)
        
        // Listen to shared words changes
        dictionaryService.$sharedWords
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateAvailableWords()
            }
            .store(in: &cancellables)
        
        // Listen to selected dictionary changes
        $selectedDictionary
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateAvailableWords()
            }
            .store(in: &cancellables)
    }
    
    private func updateAvailableDictionaries() {
        var dictionaries: [QuizDictionary] = []
        
        // Always add private dictionary if user has words
        if !wordsProvider.words.isEmpty {
            dictionaries.append(.privateDictionary)
        }
        
        // Add shared dictionaries that have words
        for dictionary in dictionaryService.sharedDictionaries {
            let wordCount = dictionaryService.sharedWords[dictionary.id]?.count ?? 0
            if wordCount > 0 {
                dictionaries.append(.sharedDictionary(dictionary))
            }
        }
        
        availableDictionaries = dictionaries
        
        // If current selection is no longer available, switch to private dictionary
        if !availableDictionaries.contains(selectedDictionary) {
            selectedDictionary = availableDictionaries.first ?? .privateDictionary
        }
    }
    
    private func updateAvailableWords() {
        switch selectedDictionary {
        case .privateDictionary:
            availableWords = wordsProvider.words
        case .sharedDictionary(let dictionary):
            availableWords = dictionaryService.sharedWords[dictionary.id] ?? []
        }
    }
}

// MARK: - Quiz Dictionary Enum

enum QuizDictionary: Hashable, Identifiable {
    case privateDictionary
    case sharedDictionary(SharedDictionary)
    
    var id: String {
        switch self {
        case .privateDictionary:
            return "private"
        case .sharedDictionary(let dictionary):
            return dictionary.id
        }
    }
    
    var name: String {
        switch self {
        case .privateDictionary:
            return "Private Dictionary"
        case .sharedDictionary(let dictionary):
            return dictionary.name
        }
    }
    
    var icon: String {
        switch self {
        case .privateDictionary:
            return "person"
        case .sharedDictionary:
            return "person.2"
        }
    }
    
    var wordCount: Int {
        switch self {
        case .privateDictionary:
            return WordsProvider.shared.words.count
        case .sharedDictionary(let dictionary):
            return DictionaryService.shared.sharedWords[dictionary.id]?.count ?? 0
        }
    }
}
