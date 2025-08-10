//
//  WordListViewModel.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import Combine
import SwiftUI

final class WordListViewModel: BaseViewModel {

    enum Output {
        case showWordDetails(CDWord)
        case showAddWord
        case showSharedDictionary(SharedDictionary)
        case showAddSharedDictionary
        case showAddExistingWordToShared(CDWord)
    }

    enum Input {
        case deleteWord(word: CDWord)
        case filterChanged(FilterCase, tag: CDTag? = nil)
    }

    var output = PassthroughSubject<Output, Never>()

    @Published var searchText = ""
    @Published var selectedWord: CDWord?
    @Published private(set) var words: [CDWord] = []
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
    @Published var selectedTag: CDTag?
    @Published private(set) var availableTags: [CDTag] = []

    private let wordsProvider: WordsProvider = .shared
    private let tagService: TagService = .shared
    private var cancellables = Set<AnyCancellable>()

    var wordsFiltered: [CDWord] {
        switch filterState {
        case .none:
            return words
        case .favorite:
            return favoriteWords
        case .search:
            return searchResults
        case .tag:
            return tagFilteredWords
        case .new:
            return words.filter { $0.difficultyLevel == 0 }
        case .inProgress:
            return words.filter { $0.difficultyLevel == 1 }
        case .needsReview:
            return words.filter { $0.difficultyLevel == 2 }
        case .mastered:
            return words.filter { $0.difficultyLevel == 3 }
        @unknown default:
            fatalError("Unhandled event")
        }
    }

    var favoriteWords: [CDWord] {
        words.filter { $0.isFavorite }
    }

    var searchResults: [CDWord] {
        words.filter { word in
            guard !searchText.isEmpty else { return true }
            return word.wordItself?.localizedStandardContains(searchText) ?? false
        }
    }
    
    var tagFilteredWords: [CDWord] {
        guard let selectedTag = selectedTag else { return words }
        return words.filter { word in
            word.tagsArray.contains { $0.id == selectedTag.id }
        }
    }

    var wordsCount: String {
        if wordsFiltered.count == 1 {
            return "1 word"
        } else {
            return "\(wordsFiltered.count) words"
        }
    }
    
    var filterStateTitle: String {
        switch filterState {
        case .none:
            return "All Words"
        case .favorite:
            return "Favorite Words"
        case .search:
            return "Search Results"
        case .tag:
            return selectedTag?.name ?? "Tagged Words"
        case .new:
            return "New Words"
        case .inProgress:
            return "Words In Progress"
        case .needsReview:
            return "Words Needing Review"
        case .mastered:
            return "Mastered Words"
        @unknown default:
            return "Words"
        }
    }

    override init() {
        super.init()
        setupBindings()
    }

    func handle(_ input: Input) {
        switch input {
        case .deleteWord(let word):
            deleteWord(word)
        case .filterChanged(let filter, let tag):
            filterState = filter
            selectedTag = tag
        }
    }

    private func setupBindings() {
        wordsProvider.$words
            .receive(on: RunLoop.main)
            .sink { [weak self] words in
                // Filter out shared words from the main word list
                let privateWords = words.filter { !$0.isSharedWord }
                self?.words = privateWords
                self?.sortWords()
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

        tagService.$tags
            .receive(on: DispatchQueue.main)
            .sink { [weak self] tags in
                self?.availableTags = tags
            }
            .store(in: &cancellables)

        // Observe real-time updates from DataSyncService
        DataSyncService.shared.realTimeUpdateReceived
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                print("🔄 [WordListViewModel] Real-time update received, refreshing words")
                self?.wordsProvider.fetchWords()
            }
            .store(in: &cancellables)
    }

    private func deleteWord(_ wordModel: CDWord) {
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
                    guard let id = wordModel.id?.uuidString else { return }
                    try? self?.wordsProvider.deleteWord(with: id)
                }
            )
        )
    }

    // MARK: - Sorting

    private func sortWords() {
        switch sortingState {
        case .earliest:
            words.sort(by: { lhs, rhs in
                (lhs.timestamp ?? Date()) < (rhs.timestamp ?? Date())
            })
        case .latest:
            words.sort(by: { lhs, rhs in
                (lhs.timestamp ?? Date()) > (rhs.timestamp ?? Date())
            })
        case .alphabetically:
            words.sort(by: { lhs, rhs in
                (lhs.wordItself ?? "") < (rhs.wordItself ?? "")
            })
        case .partOfSpeech:
            words.sort(by: { lhs, rhs in
                (lhs.partOfSpeech ?? "") < (rhs.partOfSpeech ?? "")
            })
        @unknown default:
            fatalError("Unhandled event")
        }
    }
}
