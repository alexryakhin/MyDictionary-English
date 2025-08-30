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
        case showAddWord(String)
        case showSharedDictionaries
        case showAddExistingWordToShared(CDWord)
    }

    enum Input {
        case deleteWord(word: CDWord)
        case filterChanged(FilterCase, tag: CDTag? = nil, language: InputLanguage? = nil)
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
    @Published var selectedLanguage: InputLanguage?
    @Published private(set) var availableTags: [CDTag] = []
    @Published private(set) var availableLanguages: [InputLanguage] = []

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
        case .language:
            return languageFilteredWords
        case .new:
            return words.filter { $0.difficultyLevel == .new }
        case .inProgress:
            return words.filter { $0.difficultyLevel == .inProgress }
        case .needsReview:
            return words.filter { $0.difficultyLevel == .needsReview }
        case .mastered:
            return words.filter { $0.difficultyLevel == .mastered }
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
        guard let selectedTag else { return words }
        return words.filter { word in
            word.tagsArray.contains { $0.id == selectedTag.id }
        }
    }
    
    var languageFilteredWords: [CDWord] {
        guard let selectedLanguage else { return words }
        return words.filter { word in
            word.languageCode == selectedLanguage.rawValue
        }
    }

    var wordsCount: String {
        Loc.Plurals.Words.wordsCount(wordsFiltered.count)
    }
    
    var filterStateTitle: String {
        switch filterState {
        case .none:
            return Loc.Words.allWords
        case .favorite:
            return Loc.Words.favoriteWords
        case .search:
            return Loc.Words.searchResults
        case .tag:
            return selectedTag?.name ?? Loc.Words.taggedWords
        case .language:
            return selectedLanguage?.displayName ?? Loc.Words.language
        case .new:
            return Loc.Words.newWords
        case .inProgress:
            return Loc.Words.wordsInProgress
        case .needsReview:
            return Loc.Words.wordsNeedingReview
        case .mastered:
            return Loc.Words.masteredWords
        @unknown default:
            return Loc.Words.words
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
        case .filterChanged(let filter, let tag, let language):
            filterState = filter
            selectedTag = tag
            selectedLanguage = language
        }
    }

    private func setupBindings() {
        wordsProvider.$words
            .receive(on: RunLoop.main)
            .sink { [weak self] words in
                self?.words = words
                self?.sortWords()
                self?.availableLanguages = words.compactMap {
                    InputLanguage(rawValue: $0.languageCode ?? "en")
                }
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
    }

    private func deleteWord(_ wordModel: CDWord) {
        showAlert(
            withModel: .init(
                title: Loc.Words.deleteWord,
                message: Loc.Words.deleteWordConfirmation,
                actionText: Loc.Actions.cancel,
                destructiveActionText: Loc.Actions.delete,
                action: {
                    AnalyticsService.shared.logEvent(.wordRemovingCanceled)
                },
                destructiveAction: { [weak self, wordModel] in
                    guard let id = wordModel.id?.uuidString else { return }
                    try? self?.wordsProvider.delete(with: id)
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
