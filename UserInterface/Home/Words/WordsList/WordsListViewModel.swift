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
        case showWordDetails(UUID)
        case deleteWord(IndexSet)
        case selectFilterState(FilterCase)
        case selectSortingState(SortingCase)
    }

    enum Output {
        case showAddWord
        case showWordDetails(UUID)
    }

    var onOutput: ((Output) -> Void)?

    @Published private(set) var words: [CoreWord] = []
    @Published private(set) var sortingState: SortingCase = .def
    @Published private(set) var filterState: FilterCase = .none
    @Published var searchText = ""

    private let wordsProvider: WordsProviderInterface
    private let wordsManager: WordsManagerInterface
    private var cancellables = Set<AnyCancellable>()

    var wordsFiltered: [CoreWord] {
        switch filterState {
        case .none:
            return words
        case .favorite:
            return favoriteWords
        case .search:
            return searchResults
        }
    }

    var favoriteWords: [CoreWord] {
        words.filter { $0.isFavorite }
    }

    var searchResults: [CoreWord] {
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
        wordsProvider: WordsProviderInterface,
        wordsManager: WordsManagerInterface
    ) {
        self.wordsProvider = wordsProvider
        self.wordsManager = wordsManager
        super.init()
        loadingStarted()
        setupBindings()
    }

    func handle(_ input: Input) {
        switch input {
        case .showAddWord:
            onOutput?(.showAddWord)
        case .showWordDetails(let id):
            onOutput?(.showWordDetails(id))
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
        do {
            try wordsManager.delete(with: id)
            saveContext()
        } catch {
            errorReceived(error, displayType: .snack)
        }
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

    private func saveContext() {
        do {
            try wordsManager.saveContext()
        } catch {
            errorReceived(error, displayType: .snack)
        }
    }
}
