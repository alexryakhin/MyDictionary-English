//
//  QuizWordsProvider.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import Foundation
import Combine
#if os(iOS)
import UIKit
#endif

/// Service that provides words for quizzes from both private and shared dictionaries
final class QuizWordsProvider: ObservableObject {
    static let shared = QuizWordsProvider()
    
    @Published var availableWords: [any QuizWord] = []
    @Published var selectedDictionary: QuizDictionary = .privateDictionary
    @Published var availableDictionaries: [QuizDictionary] = []
    
    private lazy var wordsProvider: WordsProvider = .shared
    private lazy var dictionaryService: DictionaryService = .shared
    private var cancellables = Set<AnyCancellable>()

    private init() {
        // Defer setup to avoid initialization order issues
        DispatchQueue.main.async { [weak self] in
            self?.setupBindings()
            self?.refreshAvailableDictionaries()
        }
    }
    
    // MARK: - Public Methods
    
    /// Forces a refresh of available dictionaries and words
    func refreshAvailableDictionaries() {
        updateAvailableDictionaries()
        updateAvailableWords()
    }
    
    /// Resets the service state (useful when user signs out/in)
    func reset() {
        availableWords = []
        availableDictionaries = []
        selectedDictionary = .privateDictionary
    }
    
    /// Manually loads words for a shared dictionary
    func loadWordsForSharedDictionary(_ dictionary: SharedDictionary) {
        setupListenerForDictionary(dictionary.id)
    }
    
    /// Gets words for a quiz based on the selected dictionary and filters
    /// - Parameters:
    ///   - preset: Quiz preset containing word count and difficulty settings
    /// - Returns: Array of words for the quiz (all available words, not limited by word count)
    func getWordsForQuiz(with preset: QuizPreset) -> [any QuizWord] {
        let filteredWords = preset.hardWordsOnly
        ? availableWords.filter { $0.difficultyLevel == .needsReview }
        : availableWords

        return Array(filteredWords.shuffled())
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

        #if os(iOS)
        // Listen to app becoming active to refresh dictionaries
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.refreshAvailableDictionaries()
            }
            .store(in: &cancellables)
        #endif
    }
    
    private func updateAvailableDictionaries() {
        var dictionaries: [QuizDictionary] = [.privateDictionary]

        // Add ALL shared dictionaries that the user has access to
        // Don't filter by word count - let the UI show placeholders when needed
        for dictionary in dictionaryService.sharedDictionaries {
            dictionaries.append(.sharedDictionary(dictionary))
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
            // Get words from cache
            let cachedWords = dictionaryService.sharedWords[dictionary.id] ?? []
            availableWords = cachedWords
        }
    }
    
    private func setupListenerForDictionary(_ dictionaryId: String) {
        dictionaryService.listenToSharedDictionaryWords(dictionaryId: dictionaryId)
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
            return Loc.Words.privateDictionary.localized
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
