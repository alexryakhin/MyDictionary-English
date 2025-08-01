//
//  WordsListViewModel.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import Combine
import SwiftUI

class WordsListViewModel: BaseViewModel {

    enum Input {
        case showAddWord
        case showWordDetails(word: Word)
        case deleteWord(word: Word)
    }

    enum Output {
        case showAddWord(searchText: String)
        case showWordDetails(word: Word)
    }

    var onOutput: ((Output) -> Void)?

    @Published var searchText = ""

    @Published private(set) var words: [Word] = []
    @Published var sortingState: SortingCase = .latest {
        didSet {
            sortWords()
            AnalyticsService.shared.logEvent(.wordsListSortingSelected)
        }
    }
    @Published var filterState: FilterCase = .none {
        didSet {
            sortWords()
            AnalyticsService.shared.logEvent(.wordsListFilterSelected)
        }
    }

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

    override init() {
        self.wordsProvider = ServiceManager.shared.wordsProvider
        super.init()
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
        }
    }

    private func setupBindings() {
        wordsProvider.wordsPublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] words in
                if words.isNotEmpty {
                    self?.words = words
                    self?.sortWords()
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

    // MARK: - Sorting

    private func sortWords() {
        switch sortingState {
        case .earliest:
            words.sort(by: { lhs, rhs in
                lhs.timestamp < rhs.timestamp
            })
        case .latest:
            words.sort(by: { lhs, rhs in
                lhs.timestamp > rhs.timestamp
            })
        case .alphabetically:
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
