//
//  QuizWordsProvider.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import Foundation
import Combine
import UIKit

/// Service that provides words for quizzes from both private and shared dictionaries
final class QuizWordsProvider: ObservableObject {
    static let shared = QuizWordsProvider()
    
    @Published var availableWords: [any QuizWord] = []
    @Published var selectedDictionary: QuizDictionary = .privateDictionary
    @Published var availableDictionaries: [QuizDictionary] = []
    
    private lazy var wordsProvider: WordsProvider = .shared
    private lazy var dictionaryService: DictionaryService = .shared
    private var cancellables = Set<AnyCancellable>()
    private var dictionariesWithListeners: Set<String> = [] // Track which dictionaries have listeners set up
    
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
        print("🔄 [QuizWordsProvider] Forcing refresh of available dictionaries")
        updateAvailableDictionaries()
        updateAvailableWords()
    }
    
    /// Resets the service state (useful when user signs out/in)
    func reset() {
        print("🔄 [QuizWordsProvider] Resetting service state")
        dictionariesWithListeners.removeAll()
        availableWords = []
        availableDictionaries = []
        selectedDictionary = .privateDictionary
    }
    
    /// Manually loads words for a shared dictionary
    func loadWordsForSharedDictionary(_ dictionary: SharedDictionary) {
        print("🔄 [QuizWordsProvider] Manually loading words for shared dictionary: \(dictionary.name)")
        setupListenerForDictionary(dictionary.id)
    }
    
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
        
        // Listen to app becoming active to refresh dictionaries
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.refreshAvailableDictionaries()
            }
            .store(in: &cancellables)
    }
    
    private func updateAvailableDictionaries() {
        var dictionaries: [QuizDictionary] = []
        
        // Always add private dictionary if user has words
        if !wordsProvider.words.isEmpty {
            dictionaries.append(.privateDictionary)
        }
        
        // Add ALL shared dictionaries that the user has access to
        // Don't filter by word count - let the UI show placeholders when needed
        for dictionary in dictionaryService.sharedDictionaries {
            dictionaries.append(.sharedDictionary(dictionary))
        }
        
        // Clean up listeners for dictionaries that are no longer available
        let currentDictionaryIds = Set(dictionaryService.sharedDictionaries.map { $0.id })
        let removedDictionaryIds = dictionariesWithListeners.subtracting(currentDictionaryIds)
        for dictionaryId in removedDictionaryIds {
            dictionariesWithListeners.remove(dictionaryId)
            print("🧹 [QuizWordsProvider] Removed listener tracking for dictionary: \(dictionaryId)")
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
            print("📊 [QuizWordsProvider] Updated available words for private dictionary: \(wordsProvider.words.count) words")
        case .sharedDictionary(let dictionary):
            // Get words from cache
            let cachedWords = dictionaryService.sharedWords[dictionary.id] ?? []
            print("📊 [QuizWordsProvider] Checking cached words for shared dictionary '\(dictionary.name)': \(cachedWords.count) words")
            
            // If no words are cached and we haven't set up a listener yet, trigger loading
            if cachedWords.isEmpty && !dictionariesWithListeners.contains(dictionary.id) {
                print("🔄 [QuizWordsProvider] Loading words for shared dictionary: \(dictionary.name)")
                setupListenerForDictionary(dictionary.id)
            }
            
            availableWords = cachedWords
            print("📊 [QuizWordsProvider] Updated available words for shared dictionary '\(dictionary.name)': \(cachedWords.count) words")
        }
    }
    
    private func setupListenerForDictionary(_ dictionaryId: String) {
        // Only set up listener if we haven't already
        guard !dictionariesWithListeners.contains(dictionaryId) else {
            print("🔄 [QuizWordsProvider] Listener already set up for dictionary: \(dictionaryId), skipping")
            return
        }
        
        print("🔄 [QuizWordsProvider] Setting up new listener for dictionary: \(dictionaryId)")
        dictionaryService.listenToSharedDictionaryWords(dictionaryId: dictionaryId)
        dictionariesWithListeners.insert(dictionaryId)
        print("✅ [QuizWordsProvider] Successfully set up listener for dictionary: \(dictionaryId)")
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
