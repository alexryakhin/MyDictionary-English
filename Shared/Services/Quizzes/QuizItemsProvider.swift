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

    private lazy var wordsProvider: WordsProvider = .shared
    private lazy var idiomsProvider: IdiomsProvider = .shared
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

    /// Gets words for a quiz based on the selected dictionary and filters
    /// - Parameters:
    ///   - preset: Quiz preset containing word count and difficulty settings
    /// - Returns: Array of words for the quiz (all available words, not limited by word count)
    func getItemsForQuiz(with preset: QuizPreset) -> [any Quizable] {
        let filteredItems = preset.hardItemsOnly
        ? availableItems.filter { $0.difficultyLevel == .needsReview }
        : availableItems

        return Array(filteredItems.shuffled())
    }

    /// Checks if there are enough words available for a quiz
    /// - Parameters:
    ///   - wordCount: Number of words needed
    ///   - hardItemsOnly: Whether to only include difficult words
    /// - Returns: Whether enough words are available
    func hasEnoughItems(itemCount: Int, hardItemsOnly: Bool = false) -> Bool {
        let filteredItems = hardItemsOnly
        ? availableItems.filter { $0.difficultyLevel == .needsReview }
        : availableItems

        return filteredItems.count >= itemCount
    }

    /// Gets the minimum required words for hard words mode
    /// - Returns: Number of hard words available
    func getHardItemsCount() -> Int {
        return availableItems.filter { $0.difficultyLevel == .needsReview }.count
    }

    /// Gets the total number of words available
    /// - Returns: Total number of words
    func getTotalItemsCount() -> Int {
        return availableItems.count
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
            }
            .store(in: &cancellables)

        wordsProvider.$words
            .combineLatest(idiomsProvider.$idioms)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateAvailableItems()
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
            availableItems = wordsProvider.words + idiomsProvider.idioms
        case .sharedDictionary(let dictionary):
            // Get words from cache
            let cachedItems = dictionaryService.sharedWords[dictionary.id] ?? []
            availableItems = cachedItems
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
