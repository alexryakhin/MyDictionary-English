//
//  SharedWordListViewModel.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/9/25.
//

import Combine
import SwiftUI

final class SharedWordListViewModel: BaseViewModel {

    enum Input {
        case filterChanged(FilterCase, language: InputLanguage? = nil)
    }

    @Published var searchText = ""
    @Published var selectedWord: SharedWord?
    @Published private(set) var words: [SharedWord] = []
    @Published var sortingState: SortingCase = .latest {
        didSet {
            sortWords()
        }
    }
    @Published var filterState: FilterCase = .none {
        didSet {
            sortWords()
        }
    }
    @Published var selectedLanguage: InputLanguage?
    @Published private(set) var availableLanguages: [InputLanguage] = []

    private let dictionaryService = DictionaryService.shared
    private let authenticationService = AuthenticationService.shared
    private var cancellables = Set<AnyCancellable>()
    private let dictionaryId: String

    var wordsFiltered: [SharedWord] {
        switch filterState {
        case .none:
            return words
        case .favorite:
            return favoriteWords
        case .search:
            return searchResults
        case .new:
            return words.filter { getDifficultyForWord($0) == .new }
        case .inProgress:
            return words.filter { getDifficultyForWord($0) == .inProgress }
        case .needsReview:
            return words.filter { getDifficultyForWord($0) == .needsReview }
        case .mastered:
            return words.filter { getDifficultyForWord($0) == .mastered }
        case .language:
            return languageFilteredWords
        @unknown default:
            fatalError("Unhandled event")
        }
    }

    var favoriteWords: [SharedWord] {
        guard let userEmail = authenticationService.userEmail else { return [] }
        return words.filter { $0.isLikedBy(userEmail) }
    }

    var searchResults: [SharedWord] {
        words.filter { word in
            guard !searchText.isEmpty else { return true }
            return word.wordItself.localizedStandardContains(searchText) ||
                   word.definition.localizedStandardContains(searchText)
        }
    }
    
    var languageFilteredWords: [SharedWord] {
        guard let selectedLanguage else { return words }
        return words.filter { word in
            word.languageCode == selectedLanguage.rawValue
        }
    }

    var wordsCount: String {
        Loc.Plurals.Words.wordsCount(wordsFiltered.count)
    }
    
    var filterStateTitle: String {
        switch filterState {
        case .none:
            return Loc.FilterDisplay.all
        case .favorite:
            return Loc.FilterDisplay.favorite
        case .search:
            return Loc.FilterDisplay.search
        case .language:
            return selectedLanguage?.displayName ?? Loc.Words.language
        case .new:
            return Loc.FilterDisplay.new
        case .inProgress:
            return Loc.FilterDisplay.inProgress
        case .needsReview:
            return Loc.FilterDisplay.needsReview
        case .mastered:
            return Loc.FilterDisplay.mastered
        @unknown default:
            return Loc.Words.words
        }
    }

    init(dictionaryId: String) {
        self.dictionaryId = dictionaryId
        super.init()
        setupBindings()
    }

    func handle(_ input: Input) {
        switch input {
        case .filterChanged(let filter, let language):
            filterState = filter
            selectedLanguage = language
        }
    }

    private func setupBindings() {
        // Listen to shared words for this dictionary
        dictionaryService.$sharedWords
            .receive(on: RunLoop.main)
            .sink { [weak self] sharedWords in
                guard let self = self else { return }
                self.words = sharedWords[self.dictionaryId] ?? []
                self.sortWords()
                self.availableLanguages = self.words.compactMap {
                    InputLanguage(rawValue: $0.languageCode)
                }.removedDuplicates
            }
            .store(in: &cancellables)

        // React to the search input from a user
        $searchText
            .sink { [weak self] value in
                self?.filterState = value.isEmpty ? .none : .search
            }
            .store(in: &cancellables)

        $selectedWord
            .compactMap { $0 }
            .sink { _ in
                AnalyticsService.shared.logEvent(.wordOpened)
            }
            .store(in: &cancellables)
    }

    private func sortWords() {
        // Sorting is handled by the filtered words computed property
        // This method can be used for additional sorting logic if needed
    }

    func getDifficultyForWord(_ word: SharedWord) -> Difficulty {
        guard let userEmail = authenticationService.userEmail else { return .new }
        let difficultyScore = word.getDifficultyFor(userEmail)
        return Difficulty(score: difficultyScore)
    }
}
