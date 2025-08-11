import SwiftUI
import Combine
import CoreData

final class WordsViewModel: BaseViewModel {

    // MARK: - properties

    @Published var searchText = ""
    @Published private(set) var words: [CDWord] = []
    @Published var selectedWord: CDWord?
    @Published var sortingState: SortingCase = .latest {
        didSet {
            sortWords()
        }
    }
    @Published var filterState: FilterCase = .none

    // MARK: - Private properties

    private let wordsProvider: WordsProvider = .shared
    private let ttsPlayer: TTSPlayer = .shared
    private let coreDataService: CoreDataService = .shared
    // No longer need wordDetailsManager since we work directly with Core Data objects
    private var cancellables = Set<AnyCancellable>()
    private var wordDetailsSubscription: AnyCancellable?

    // MARK: - Init

    override init() {
        super.init()
        setupBindings()
    }

    func deleteWord(offsets: IndexSet) {
        switch filterState {
        case .none:
            withAnimation {
                offsets.map { words[$0] }.forEach { [weak self] word in
                    guard let id = word.id?.uuidString else { return }
                    self?.deleteWord(withID: id)
                }
            }
        case .favorite:
            withAnimation {
                offsets.map { favoriteWords[$0] }.forEach { [weak self] word in
                    guard let id = word.id?.uuidString else { return }
                    self?.deleteWord(withID: id)
                }
            }
        case .search:
            withAnimation {
                offsets.map { searchResults[$0] }.forEach { [weak self] word in
                    guard let id = word.id?.uuidString else { return }
                    self?.deleteWord(withID: id)
                }
            }
        case .new, .inProgress, .needsReview, .mastered:
            withAnimation {
                offsets.map { wordsFiltered[$0] }.forEach { [weak self] word in
                    guard let id = word.id?.uuidString else { return }
                    self?.deleteWord(withID: id)
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

    private func setupBindings() {
        wordsProvider.$words
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

        $selectedWord
            .compactMap { $0 }
            .sink { _ in
                AnalyticsService.shared.logEvent(.wordOpened)
            }
            .store(in: &cancellables)
        
        // Observe real-time updates from DataSyncService
        DataSyncService.shared.$realTimeUpdateReceived
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                print("🔄 [WordsViewModel] Real-time update received, refreshing words")
                self?.wordsProvider.fetchWords()
            }
            .store(in: &cancellables)
    }

    private func updateWords(_ words: [CDWord]) {
        self.words = words
        sortWords()
        if let selectedWord = words.first(where: { $0.id?.uuidString == selectedWord?.id?.uuidString }) {
            self.selectedWord = selectedWord
        } else {
            selectedWord = nil
        }
    }
}

// MARK: - Words List

private extension WordsViewModel {

    // MARK: - Sorting

    func sortWords() {
        switch sortingState {
        case .earliest:
            words.sort(by: { word1, word2 in
                (word1.timestamp ?? Date()) < (word2.timestamp ?? Date())
            })
        case .latest:
            words.sort(by: { word1, word2 in
                (word1.timestamp ?? Date()) > (word2.timestamp ?? Date())
            })
        case .alphabetically:
            words.sort(by: { word1, word2 in
                (word1.wordItself ?? "") < (word2.wordItself ?? "")
            })
        case .partOfSpeech:
            words.sort(by: { word1, word2 in
                (word1.partOfSpeech ?? "") < (word2.partOfSpeech ?? "")
            })
        @unknown default:
            fatalError("Unknown sorting case")
        }
    }
}

extension WordsViewModel {
    var favoriteWords: [CDWord] {
        words.filter { $0.isFavorite }
    }

    var searchResults: [CDWord] {
        words.filter { [weak self] word in
            guard let self, !searchText.isEmpty else { return true }
            return word.wordItself?.localizedStandardContains(searchText) ?? false
        }
    }
    
    var wordsFiltered: [CDWord] {
        switch filterState {
        case .none: words
        case .favorite: favoriteWords
        case .search: searchResults
        case .new: words.filter { $0.difficultyLevel == .new }
        case .inProgress: words.filter { $0.difficultyLevel == .inProgress }
        case .needsReview: words.filter { $0.difficultyLevel == .needsReview }
        case .mastered: words.filter { $0.difficultyLevel == .mastered }
        @unknown default: fatalError("Unknown filter state")
        }
    }
}
