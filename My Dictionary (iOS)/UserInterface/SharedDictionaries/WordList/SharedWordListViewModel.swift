//
//  SharedWordListViewModel.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/9/25.
//

import Combine
import SwiftUI

final class SharedWordListViewModel: BaseViewModel {

    enum Output {
        case showWordDetails(SharedWord)
        case showAddWord(String)
    }

    enum Input {
        case filterChanged(FilterCase)
    }

    var output = PassthroughSubject<Output, Never>()

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
        case .tag:
            // Shared words don't have tags, so return all words
            return words
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

    var wordsCount: String {
        Loc.Words.wordsCount.localized(wordsFiltered.count)
    }
    
    var filterStateTitle: String {
        switch filterState {
        case .none:
            return Loc.FilterDisplay.all.localized
        case .favorite:
            return Loc.FilterDisplay.favorite.localized
        case .search:
            return Loc.FilterDisplay.search.localized
        case .tag:
            return Loc.FilterDisplay.all.localized // Shared words don't have tags
        case .new:
            return Loc.FilterDisplay.new.localized
        case .inProgress:
            return Loc.FilterDisplay.inProgress.localized
        case .needsReview:
            return Loc.FilterDisplay.needsReview.localized
        case .mastered:
            return Loc.FilterDisplay.mastered.localized
        @unknown default:
            return Loc.Words.words.localized
        }
    }

    init(dictionaryId: String) {
        self.dictionaryId = dictionaryId
        super.init()
        setupBindings()
    }

    func handle(_ input: Input) {
        switch input {
        case .filterChanged(let filter):
            filterState = filter
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
