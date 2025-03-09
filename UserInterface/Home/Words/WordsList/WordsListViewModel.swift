//
//  WordsListViewModel.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import Core
import CoreUserInterface
import CoreNavigation
import Services
import Combine

public class WordsListViewModel: DefaultPageViewModel {

    enum Input {
        case showAddWord
        case showWordDetails(word: Word)
        case deleteWord(IndexSet)
        case selectFilterState(FilterCase)
        case selectSortingState(SortingCase)
    }

    enum Output {
        case showAddWord
        case showWordDetails(word: Word)
    }

    var onOutput: ((Output) -> Void)?

    @Published private(set) var words: [Word] = []
    @Published private(set) var sortingState: SortingCase = .def
    @Published private(set) var filterState: FilterCase = .none
    @Published var searchText = ""

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

    var wordsCount: String {
        if wordsFiltered.count == 1 {
            return "1 word"
        } else {
            return "\(wordsFiltered.count) words"
        }
    }

    public init(
        wordsProvider: WordsProviderInterface
    ) {
        self.wordsProvider = wordsProvider
        super.init()
        loadingStarted()
        setupBindings()
    }

    func handle(_ input: Input) {
        switch input {
        case .showAddWord:
            onOutput?(.showAddWord)
        case .showWordDetails(let word):
            onOutput?(.showWordDetails(word: word))
        case .deleteWord(let offsets):
            deleteWord(offsets: offsets)
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

    private func deleteWord(offsets: IndexSet) {
        switch filterState {
        case .none:
            offsets.map { words[$0] }.forEach { [weak self] word in
                self?.deleteWord(with: word.id)
            }
        case .favorite:
            offsets.map { favoriteWords[$0] }.forEach { [weak self] word in
                self?.deleteWord(with: word.id)
            }
        case .search:
            offsets.map { searchResults[$0] }.forEach { [weak self] word in
                self?.deleteWord(with: word.id)
            }
        }
    }

    private func deleteWord(with id: UUID) {
        wordsProvider.delete(with: id)
    }

    private func selectFilterState(_ filterState: FilterCase) {
        self.filterState = filterState
        sortWords()
    }

    // MARK: - Sorting

    private func selectSortingState(_ sortingState: SortingCase) {
        self.sortingState = sortingState
        sortWords()
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
                lhs.partOfSpeech < rhs.partOfSpeech
            })
        }
    }
}
