//
//  WordsListViewModel.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import Core
import CoreUserInterface
import Services
import Combine
import SwiftUI

public class WordsListViewModel: DefaultPageViewModel {

    enum Input {
        case showAddWord
        case showWordDetails(word: Word)
        case deleteWord(word: Word)
        case selectFilterState(FilterCase)
        case selectSortingState(SortingCase)
    }

    enum Output {
        case showAddWord(searchText: String)
        case showWordDetails(word: Word)
    }

    var onOutput: ((Output) -> Void)?

    @Published var searchText = ""

    @Published private(set) var words: [Word] = []
    @Published private(set) var sortingState: SortingCase = .def
    @Published private(set) var filterState: FilterCase = .none

    private let wordsProvider: WordsProviderInterface
    private var cancellables = Set<AnyCancellable>()

    var wordsFiltered: [Word] {
        switch filterState {
        case .none:
            return words
        case .favorite:
            return favoriteWords
        case .search:
            return searchResults
        @unknown default:
            fatalError("Unhandled event")
        }
    }

    var favoriteWords: [Word] {
        words.filter { $0.isFavorite }
    }

    var searchResults: [Word] {
        words.filter { word in
            guard !searchText.isEmpty else { return true }
            return word.word.localizedStandardContains(searchText)
        }
    }

    var wordsCount: LocalizedStringKey {
        if wordsFiltered.count == 1 {
            return "1 word"
        } else {
            return "\(wordsFiltered.count) words"
        }
    }

    public init(wordsProvider: WordsProviderInterface) {
        self.wordsProvider = wordsProvider
        super.init()
        loadingStarted()
        setupBindings()
    }

    func handle(_ input: Input) {
        switch input {
        case .showAddWord:
            onOutput?(.showAddWord(searchText: searchText))
        case .showWordDetails(let word):
            onOutput?(.showWordDetails(word: word))
        case .deleteWord(let word):
            deleteWord(word)
        case .selectFilterState(let filter):
            selectFilterState(filter)
        case .selectSortingState(let sorting):
            selectSortingState(sorting)
        }
    }

    private func setupBindings() {
        wordsProvider.wordsPublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] words in
                if words.isNotEmpty {
                    self?.words = words
                    self?.sortWords()
                    self?.resetAdditionalState()
                } else {
                    self?.additionalState = .placeholder()
                }
            }
            .store(in: &cancellables)

        // React to the search input from a user
        $searchText
            .sink { [weak self] value in
                self?.filterState = value.isEmpty ? .none : .search
            }
            .store(in: &cancellables)
    }

    private func deleteWord(_ wordModel: Word) {
        showAlert(
            withModel: .init(
                title: "Delete word",
                message: "Are you sure you want to delete this word?",
                actionText: "Cancel",
                destructiveActionText: "Delete",
                action: {
                    AnalyticsService.shared.logEvent(.wordRemovingCanceled)
                },
                destructiveAction: { [weak self, wordModel] in
                    self?.wordsProvider.delete(with: wordModel.id)
                }
            )
        )
    }

    private func selectFilterState(_ filterState: FilterCase) {
        self.filterState = filterState
        sortWords()
        AnalyticsService.shared.logEvent(.wordsListFilterSelected)
    }

    // MARK: - Sorting

    private func selectSortingState(_ sortingState: SortingCase) {
        self.sortingState = sortingState
        sortWords()
        AnalyticsService.shared.logEvent(.wordsListSortingSelected)
    }

    private func sortWords() {
        switch sortingState {
        case .def:
            words.sort(by: { lhs, rhs in
                lhs.timestamp < rhs.timestamp
            })
        case .name:
            words.sort(by: { lhs, rhs in
                lhs.word < rhs.word
            })
        case .partOfSpeech:
            words.sort(by: { lhs, rhs in
                lhs.partOfSpeech.rawValue < rhs.partOfSpeech.rawValue
            })
        @unknown default:
            fatalError("Unhandled event")
        }
    }
}
