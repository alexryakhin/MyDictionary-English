import SwiftUI
import Combine
import CoreData
import CoreUserInterface__macOS_
import Services
import Shared
import Core

final class WordsViewModel: DefaultPageViewModel {

    private let wordsProvider: WordsProviderInterface
    private var wordDetailsManager: WordDetailsManagerInterface?
    private let ttsPlayer: TTSPlayerInterface
    private var cancellables = Set<AnyCancellable>()

    @Published var words: [Word] = []
    @Published var selectedWord: Word? {
        didSet {
            if let selectedWord {
                wordDetailsManager = DIContainer.shared.resolver.resolve(WordDetailsManagerInterface.self, argument: selectedWord.id)!
            } else {
                wordDetailsManager = nil
            }
        }
    }
    @Published var sortingState: SortingCase = .def
    @Published var filterState: FilterCase = .none
    @Published var searchText = ""

    @Published var isShowAddExample = false
    @Published var definitionTextFieldStr = ""
    @Published var exampleTextFieldStr = ""

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
        words.filter { [weak self] word in
            guard let self, !searchText.isEmpty else { return true }
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

    override init() {
        self.wordsProvider = DIContainer.shared.resolver.resolve(WordsProviderInterface.self)!
        self.ttsPlayer = DIContainer.shared.resolver.resolve(TTSPlayerInterface.self)!
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
        wordsProvider.delete(with: word.id)
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
                word1.timestamp < word2.timestamp
            })
        case .name:
            words.sort(by: { word1, word2 in
                word1.word < word2.word
            })
        case .partOfSpeech:
            words.sort(by: { word1, word2 in
                word1.partOfSpeech.rawValue < word2.partOfSpeech.rawValue
            })
        }
    }
}

extension WordsViewModel {
    func removeExample(atIndex index: Int) {
        selectedWord?.examples.remove(at: index)
    }

    func removeExample(atOffsets offsets: IndexSet) {
        selectedWord?.examples.remove(atOffsets: offsets)
    }

    func saveExample() {
        selectedWord?.examples.append(exampleTextFieldStr)
        exampleTextFieldStr = ""
        isShowAddExample = false
    }

    func speak(_ text: String?) {
        Task {
            if let text {
                do {
                    try await ttsPlayer.play(text)
                } catch {
                    errorReceived(error, displayType: .alert)
                }
            }
        }
    }

    func changePartOfSpeech(_ partOfSpeech: PartOfSpeech) {
        selectedWord?.partOfSpeech = partOfSpeech
    }

    func deleteCurrentWord() {
        wordDetailsManager?.deleteWord()
        self.selectedWord = nil
    }

    func toggleFavorite() {
        selectedWord?.isFavorite.toggle()
    }
}
