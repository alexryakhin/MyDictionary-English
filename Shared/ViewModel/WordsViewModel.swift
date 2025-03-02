import SwiftUI
import Combine
import CoreData

final class WordsViewModel: ViewModel {

    private let wordsProvider: WordsProviderInterface
    private let wordsManager: WordsManagerInterface
    private var cancellables = Set<AnyCancellable>()

    @Published var words: [Word] = []
    @Published var sortingState: SortingCase = .def
    @Published var filterState: FilterCase = .none
    @Published var searchText = ""

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
            guard let wordItself = word.wordItself, !searchText.isEmpty else { return true }
            return wordItself.localizedStandardContains(searchText)
        }
    }

    var wordsCount: String {
        if wordsFiltered.count == 1 {
            return "1 word"
        } else {
            return "\(wordsFiltered.count) words"
        }
    }

    init(
        wordsProvider: WordsProviderInterface,
        wordsManager: WordsManagerInterface
    ) {
        self.wordsProvider = wordsProvider
        self.wordsManager = wordsManager
        super.init()
        setupBindings()
    }

    private func setupBindings() {
        wordsProvider.wordsPublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] words in
                self?.words = words
                self?.sortWords()
            }
            .store(in: &cancellables)

        // React to the search input from a user
        $searchText
            .sink { [weak self] value in
                self?.filterState = value.isEmpty ? .none : .search
            }
            .store(in: &cancellables)
    }

    func deleteWord(offsets: IndexSet) {
        switch filterState {
        case .none:
            withAnimation {
                offsets.map { words[$0] }.forEach { [weak self] word in
                    self?.delete(word: word)
                }
            }
        case .favorite:
            withAnimation {
                offsets.map { favoriteWords[$0] }.forEach { [weak self] word in
                    self?.delete(word: word)
                }
            }
        case .search:
            withAnimation {
                offsets.map { searchResults[$0] }.forEach { [weak self] word in
                    self?.delete(word: word)
                }
            }
        }
    }

    func delete(word: Word) {
        wordsManager.delete(word: word)
        saveContext()
    }

    func selectFilterState(_ filterState: FilterCase) {
        withAnimation { [weak self] in
            self?.filterState = filterState
            self?.sortWords()
        }
    }

    // MARK: - Sorting

    func selectSortingState(_ sortingState: SortingCase) {
        withAnimation { [weak self] in
            self?.sortingState = sortingState
            self?.sortWords()
        }
    }

    func sortWords() {
        switch sortingState {
        case .def:
            words.sort(by: { word1, word2 in
                word1.timestamp! < word2.timestamp!
            })
        case .name:
            words.sort(by: { word1, word2 in
                word1.wordItself! < word2.wordItself!
            })
        case .partOfSpeech:
            words.sort(by: { word1, word2 in
                word1.partOfSpeech! < word2.partOfSpeech!
            })
        }
    }

    private func saveContext() {
        do {
            try wordsManager.saveContext()
        } catch {
            handleError(error)
        }
    }
}
