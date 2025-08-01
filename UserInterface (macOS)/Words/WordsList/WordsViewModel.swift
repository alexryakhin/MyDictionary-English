import SwiftUI
import Combine
import CoreData

final class WordsViewModel: BaseViewModel {

    enum Input {
        // MARK: Words List
        case selectWord(wordID: String)
        case deselectWord
        case deleteWord(atOffsets: IndexSet)

        // MARK: Word Details
        case updateTranscription(text: String)
        case updateDefinition(definition: String)
        case updateCDWord
        case play(String?)
        case toggleFavorite
        case updatePartOfSpeech(PartOfSpeech)
        case addExample(String)
        case updateExample(at: Int, text: String)
        case removeExample(at: Int)
        case deleteCurrentWord
    }

    // MARK: - properties

    @Published var searchText = ""
    @Published private(set) var words: [Word] = []
    @Published private(set) var selectedWord: Word?
    @Published private(set) var selectedWordId: String? {
        didSet {
            if let selectedWordId {
                wordDetailsManager = ServiceManager.shared.createWordDetailsManager(wordId: selectedWordId)
            } else {
                wordDetailsManager = nil
            }
        }
    }
    @Published var sortingState: SortingCase = .latest {
        didSet {
            sortWords()
        }
    }
    @Published var filterState: FilterCase = .none

    // MARK: - Private properties

    private let wordsProvider: WordsProviderInterface
    private let ttsPlayer: TTSPlayerInterface
    private var wordDetailsManager: WordDetailsManagerInterface? {
        didSet {
            if let wordDetailsManager {
                wordDetailsSubscription = wordDetailsManager.wordPublisher
                    .receive(on: DispatchQueue.main)
                    .sink { [weak self] word in
                        self?.selectedWord = word
                    }
            } else {
                wordDetailsSubscription = nil
                selectedWord = nil
            }
        }
    }
    private var cancellables = Set<AnyCancellable>()
    private var wordDetailsSubscription: AnyCancellable?

    // MARK: - Init

    override init() {
        self.wordsProvider = ServiceManager.shared.wordsProvider
        self.ttsPlayer = ServiceManager.shared.ttsPlayer
        super.init()
        setupBindings()
    }

    func handle(_ input: Input) {
        switch input {
        case .selectWord(let wordID):
            Task { @MainActor in
                selectedWordId = wordID
            }
        case .deselectWord:
            selectedWordId = nil
        case .deleteWord(let offsets):
            deleteWord(offsets: offsets)

        case .updateTranscription(let text):
            selectedWord?.phonetic = text
        case .updateDefinition(let definition):
            selectedWord?.definition = definition
        case .updateCDWord:
            updateCDWord()
        case .play(let text):
            play(text: text)
        case .toggleFavorite:
            toggleFavorite()
        case .updatePartOfSpeech(let value):
            updatePartOfSpeech(value)
        case .addExample(let example):
            addExample(example)
        case .updateExample(let index, let example):
            updateExample(at: index, text: example)
        case .removeExample(let index):
            removeExample(at: index)
        case .deleteCurrentWord:
            deleteCurrentWord()
        }
    }

    private func setupBindings() {
        wordsProvider.wordsPublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] words in
                self?.updateWords(words)
            }
            .store(in: &cancellables)

        // React to the search input from a user
        $searchText
            .sink { [weak self] value in
                self?.filterState = value.isEmpty ? .none : .search
            }
            .store(in: &cancellables)
    }

    private func updateWords(_ words: [Word]) {
        self.words = words
        sortWords()
        if let selectedWord = words.first(where: { $0.id == selectedWordId }) {
            self.selectedWord = selectedWord
        } else {
            selectedWord = nil
        }
    }
}

// MARK: - Words List

private extension WordsViewModel {
    func deleteWord(offsets: IndexSet) {
        switch filterState {
        case .none:
            withAnimation {
                offsets.map { words[$0] }.forEach { [weak self] word in
                    self?.deleteWord(withID: word.id)
                }
            }
        case .favorite:
            withAnimation {
                offsets.map { favoriteWords[$0] }.forEach { [weak self] word in
                    self?.deleteWord(withID: word.id)
                }
            }
        case .search:
            withAnimation {
                offsets.map { searchResults[$0] }.forEach { [weak self] word in
                    self?.deleteWord(withID: word.id)
                }
            }
        @unknown default:
            fatalError("Unknown filter state")
        }
    }

    func deleteWord(withID id: String, completion: VoidHandler? = nil) {
        showAlert(
            withModel: .init(
                title: "Delete word",
                message: "Are you sure you want to delete this word?",
                actionText: "Cancel",
                destructiveActionText: "Delete",
                action: {
                    AnalyticsService.shared.logEvent(.wordRemovingCanceled)
                },
                destructiveAction: { [weak self] in
                    self?.wordsProvider.delete(with: id)
                    AnalyticsService.shared.logEvent(.wordRemoved)
                    completion?()
                }
            )
        )
    }

    // MARK: - Sorting

    func sortWords() {
        switch sortingState {
        case .earliest:
            words.sort(by: { word1, word2 in
                word1.timestamp < word2.timestamp
            })
        case .latest:
            words.sort(by: { word1, word2 in
                word1.timestamp > word2.timestamp
            })
        case .alphabetically:
            words.sort(by: { word1, word2 in
                word1.word < word2.word
            })
        case .partOfSpeech:
            words.sort(by: { word1, word2 in
                word1.partOfSpeech.rawValue < word2.partOfSpeech.rawValue
            })
        @unknown default:
            fatalError("Unknown sorting case")
        }
    }
}

// MARK: - Word Details

private extension WordsViewModel {

    func play(text: String?) {
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

    func toggleFavorite() {
        selectedWord?.isFavorite.toggle()
        updateCDWord()
    }

    func updatePartOfSpeech(_ partOfSpeech: PartOfSpeech) {
        selectedWord?.partOfSpeech = partOfSpeech
        updateCDWord()
    }

    func addExample(_ example: String) {
        guard !example.isEmpty else {
            errorReceived(CoreError.internalError(.inputCannotBeEmpty), displayType: .alert)
            return
        }
        selectedWord?.examples.append(example)
        updateCDWord()
        AnalyticsService.shared.logEvent(.wordExampleAdded)
    }

    func updateExample(at index: Int, text: String) {
        guard !text.isEmpty else {
            errorReceived(CoreError.internalError(.inputCannotBeEmpty), displayType: .alert)
            return
        }
        selectedWord?.examples[index] = text
        updateCDWord()
        AnalyticsService.shared.logEvent(.wordExampleUpdated)
    }

    func removeExample(at index: Int) {
        selectedWord?.examples.remove(at: index)
        updateCDWord()
        AnalyticsService.shared.logEvent(.wordExampleRemoved)
    }

    func deleteCurrentWord() {
        if let selectedWord {
            deleteWord(withID: selectedWord.id) { [weak self] in
                self?.selectedWord = nil
            }
        }
    }

    func updateCDWord() {
        if let selectedWord {
            wordDetailsManager?.updateWord(selectedWord)
        }
    }
}

extension WordsViewModel {
    var favoriteWords: [Word] {
        words.filter { $0.isFavorite }
    }

    var searchResults: [Word] {
        words.filter { [weak self] word in
            guard let self, !searchText.isEmpty else { return true }
            return word.word.localizedStandardContains(searchText)
        }
    }
}
