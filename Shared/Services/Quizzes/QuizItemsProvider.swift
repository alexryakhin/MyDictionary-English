//
//  QuizItemsProvider.swift
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
final class QuizItemsProvider: ObservableObject {
    static let shared = QuizItemsProvider()

    @Published var availableItems: [any Quizable] = []
    @Published var selectedDictionary: QuizDictionary = .privateDictionary
    @Published var availableDictionaries: [QuizDictionary] = []
    @Published var selectedLanguage: InputLanguage? = nil
    @Published var availableLanguages: [InputLanguage] = []

    private lazy var wordsProvider: WordsProvider = .shared
    private lazy var dictionaryService: DictionaryService = .shared
    private var cancellables = Set<AnyCancellable>()

    private init() {
        // Load saved language filter
        if let savedLanguageCode = UDService.quizLanguageFilter,
           let savedLanguage = InputLanguage(rawValue: savedLanguageCode) {
            selectedLanguage = savedLanguage
        }
        
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
        updateAvailableItems()
    }

    /// Resets the service state (useful when user signs out/in)
    func reset() {
        availableItems = []
        availableDictionaries = []
        selectedDictionary = .privateDictionary
    }

    /// Manually loads words for a shared dictionary
    func loadItemsForSharedDictionary(_ dictionary: SharedDictionary) {
        setupListenerForDictionary(dictionary.id)
    }
    
    /// Sets the selected language for filtering quiz words
    func setSelectedLanguage(_ language: InputLanguage?) {
        selectedLanguage = language
        
        // Save to UserDefaults
        UDService.quizLanguageFilter = language?.rawValue
    }

    /// Gets words for a quiz based on the selected dictionary and filters
    /// - Parameters:
    ///   - preset: Quiz preset containing word count and difficulty settings
    /// - Returns: Array of words for the quiz (all available words, not limited by word count)
    func getItemsForQuiz(with preset: QuizPreset) -> [any Quizable] {
        var filteredItems = preset.hardItemsOnly
        ? availableItems.filter { $0.difficultyLevel == .needsReview }
        : availableItems
        
        // Apply language filter if selected
        if let selectedLanguage = selectedLanguage {
            filteredItems = filteredItems.filter { item in
                if let word = item as? CDWord {
                    return word.languageCode == selectedLanguage.rawValue
                }
                return false
            }
        }

        return Array(filteredItems.shuffled())
    }

    /// Checks if there are enough words available for a quiz
    /// - Parameters:
    ///   - wordCount: Number of words needed
    ///   - hardItemsOnly: Whether to only include difficult words
    /// - Returns: Whether enough words are available
    func hasEnoughItems(itemCount: Int, hardItemsOnly: Bool = false) -> Bool {
        var filteredItems = hardItemsOnly
        ? availableItems.filter { $0.difficultyLevel == .needsReview }
        : availableItems
        
        // Apply language filter if selected
        if let selectedLanguage = selectedLanguage {
            filteredItems = filteredItems.filter { item in
                if let word = item as? CDWord {
                    return word.languageCode == selectedLanguage.rawValue
                }
                return false
            }
        }

        return filteredItems.count >= itemCount
    }

    /// Gets the minimum required words for hard words mode
    /// - Returns: Number of hard words available
    func getHardItemsCount() -> Int {
        var hardItems = availableItems.filter { $0.difficultyLevel == .needsReview }
        
        // Apply language filter if selected
        if let selectedLanguage = selectedLanguage {
            hardItems = hardItems.filter { item in
                if let word = item as? CDWord {
                    return word.languageCode == selectedLanguage.rawValue
                }
                return false
            }
        }
        
        return hardItems.count
    }

    /// Gets the total number of words available
    /// - Returns: Total number of words
    func getTotalItemsCount() -> Int {
        var items = availableItems
        
        // Apply language filter if selected
        if let selectedLanguage = selectedLanguage {
            items = items.filter { item in
                if let word = item as? CDWord {
                    return word.languageCode == selectedLanguage.rawValue
                }
                return false
            }
        }
        
        return items.count
    }

    // MARK: - Private Methods

    private func setupBindings() {
        // Listen to shared dictionaries changes
        dictionaryService.$sharedDictionaries
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateAvailableDictionaries()
                self?.updateAvailableItems()
            }
            .store(in: &cancellables)

        // Listen to shared words changes
        dictionaryService.$sharedWords
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateAvailableItems()
            }
            .store(in: &cancellables)

        // Listen to selected dictionary changes
        $selectedDictionary
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateAvailableItems()
                self?.updateAvailableLanguages()
            }
            .store(in: &cancellables)
            
        // Listen to selected language changes
        $selectedLanguage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                // Language filter change doesn't need to update items immediately
                // Items are filtered on-demand in getItemsForQuiz
            }
            .store(in: &cancellables)

        wordsProvider.$words
            .combineLatest(wordsProvider.$expressions)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateAvailableItems()
                self?.updateAvailableLanguages()
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

    private func updateAvailableItems() {
        switch selectedDictionary {
        case .privateDictionary:
            // After migration, expressions (idioms/phrases) are part of wordsProvider.expressions
            // Use both words and expressions for comprehensive quiz coverage
            availableItems = wordsProvider.words + wordsProvider.expressions
        case .sharedDictionary(let dictionary):
            // Get words from cache
            let cachedItems = dictionaryService.sharedWords[dictionary.id] ?? []
            availableItems = cachedItems
        }
    }
    
    private func updateAvailableLanguages() {
        let languages = availableItems.compactMap { item -> InputLanguage? in
            if let word = item as? CDWord {
                return InputLanguage(rawValue: word.languageCode ?? "en")
            }
            return nil
        }
        
        // Remove duplicates and sort
        availableLanguages = Array(Set(languages)).sorted { $0.displayName < $1.displayName }
        
        // If current selected language is no longer available, clear it
        if let selectedLanguage = selectedLanguage, !availableLanguages.contains(selectedLanguage) {
            self.selectedLanguage = nil
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
            return Loc.Words.privateDictionary
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
