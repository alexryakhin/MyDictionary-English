//
//  IdiomListViewModel.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import Foundation
import Combine

@MainActor
final class IdiomListViewModel: BaseViewModel {

    enum Output {
        case showIdiomDetails(CDWord)
        case showAddIdiom(String)
    }

    enum Input {
        case deleteIdiom(idiom: CDWord)
        case filterChanged(FilterCase, tag: CDTag? = nil, language: InputLanguage? = nil)
    }

    var output = PassthroughSubject<Output, Never>()

    @Published var idioms: [CDWord] = []
    @Published var selectedIdiom: CDWord?
    @Published var sortingState: SortingCase = .latest {
        didSet {
            sortIdioms()
            AnalyticsService.shared.logEvent(.idiomsListSortingSelected)
        }
    }
    @Published var filterState: FilterCase = .none {
        didSet {
            sortIdioms()
        }
    }
    @Published var searchText = ""
    @Published var selectedTag: CDTag?
    @Published var selectedLanguage: InputLanguage?
    @Published private(set) var availableLanguages: [InputLanguage] = []

    private let wordsProvider: WordsProvider = .shared
    private let tagService: TagService = .shared
    private var cancellables = Set<AnyCancellable>()

    override init() {
        super.init()
        setupBindings()
    }

    func handle(_ input: Input) {
        switch input {
        case .deleteIdiom(let idiom):
            deleteIdiom(with: idiom.id?.uuidString ?? "")
        case .filterChanged(let filter, let tag, let language):
            filterState = filter
            selectedTag = tag
            selectedLanguage = language
        }
    }

    private func setupBindings() {
        wordsProvider.$expressions
            .receive(on: DispatchQueue.main)
            .sink { [weak self] idioms in
                self?.idioms = idioms
                self?.sortIdioms()
                self?.availableLanguages = idioms.compactMap {
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
    }

    /// Removes given idiom from Core Data
    private func deleteIdiom(with id: String) {
        showAlert(
            withModel: .deleteConfirmation(
                title: Loc.Words.deleteIdiom,
                message: Loc.Words.deleteIdiomConfirmation,
                onCancel: {
                    AnalyticsService.shared.logEvent(.idiomRemovingCanceled)
                },
                onDelete: { [weak self, id] in
                    try? self?.wordsProvider.delete(with: id)
                    AnalyticsService.shared.logEvent(.idiomRemoved)
                }
            )
        )
    }

    // MARK: - Computed Properties
    
    var idiomsFiltered: [CDWord] {
        switch filterState {
        case .none:
            return idioms
        case .favorite:
            return favoriteIdioms
        case .search:
            return searchResults
        case .new:
            return newIdioms
        case .inProgress:
            return inProgressIdioms
        case .needsReview:
            return needsReviewIdioms
        case .mastered:
            return masteredIdioms
        case .tag:
            return taggedIdioms
        case .language:
            return languageFilteredIdioms
        @unknown default:
            return idioms
        }
    }

    var favoriteIdioms: [CDWord] {
        idioms.filter { $0.isFavorite }
    }

    var searchResults: [CDWord] {
        idioms.filter { model in
            guard !searchText.isEmpty else { return true }
            return model.wordItself?.localizedStandardContains(searchText) ?? false
        }
    }

    // MARK: - Difficulty-based filtering

    var newIdioms: [CDWord] {
        idioms.filter { $0.difficultyLevel == .new }
    }

    var inProgressIdioms: [CDWord] {
        idioms.filter { $0.difficultyLevel == .inProgress }
    }

    var needsReviewIdioms: [CDWord] {
        idioms.filter { $0.difficultyLevel == .needsReview }
    }

    var masteredIdioms: [CDWord] {
        idioms.filter { $0.difficultyLevel == .mastered }
    }

    // MARK: - Tag-based filtering

    var taggedIdioms: [CDWord] {
        guard let selectedTag = selectedTag else { return idioms }
        return idioms.filter { idiom in
            idiom.tagsArray.contains { $0.id == selectedTag.id }
        }
    }

    var languageFilteredIdioms: [CDWord] {
        guard let selectedLanguage else { return idioms }
        return idioms.filter { idiom in
            idiom.languageCode == selectedLanguage.rawValue
        }
    }

    var availableTags: [CDTag] {
        tagService.tags
    }

    var idiomsCount: String {
        Loc.Plurals.Idioms.idiomsCount(idiomsFiltered.count)
    }

    var filterStateTitle: String {
        switch filterState {
        case .none:
            return Loc.Words.allIdioms
        case .favorite:
            return Loc.Words.favoriteIdioms
        case .search:
            return Loc.Words.foundIdioms
        case .new:
            return Loc.FilterDisplay.new
        case .inProgress:
            return Loc.FilterDisplay.inProgress
        case .needsReview:
            return Loc.FilterDisplay.needsReview
        case .mastered:
            return Loc.FilterDisplay.mastered
        case .tag:
            return selectedTag?.name ?? Loc.Words.idioms
        case .language:
            return selectedLanguage?.displayName ?? Loc.Words.language
        @unknown default:
            return Loc.Words.idioms
        }
    }

    private func sortIdioms() {
        switch sortingState {
        case .earliest:
            idioms.sort(by: { lhs, rhs in
                (lhs.timestamp ?? Date()) < (rhs.timestamp ?? Date())
            })
        case .latest:
            idioms.sort(by: { lhs, rhs in
                (lhs.timestamp ?? Date()) > (rhs.timestamp ?? Date())
            })
        case .alphabetically:
            idioms.sort(by: { lhs, rhs in
                (lhs.wordItself ?? "") < (rhs.wordItself ?? "")
            })
        case .partOfSpeech:
            break
        }
    }
}
