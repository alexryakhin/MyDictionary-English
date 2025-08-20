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
        case showIdiomDetails(CDIdiom)
        case showAddIdiom(String)
    }

    enum Input {
        case deleteIdiom(idiom: CDIdiom)
        case filterChanged(FilterCase, tag: CDTag? = nil)
    }

    var output = PassthroughSubject<Output, Never>()

    @Published var idioms: [CDIdiom] = []
    @Published var selectedIdiom: CDIdiom?
    @Published var sortingState: SortingCase = .latest {
        didSet {
            sortIdioms()
            AnalyticsService.shared.logEvent(.idiomsListSortingSelected)
        }
    }
    @Published var filterState: FilterCase = .none {
        didSet {
            sortIdioms()
            AnalyticsService.shared.logEvent(.idiomsListFilterSelected)
        }
    }
    @Published var searchText = ""
    @Published var selectedTag: CDTag?

    private let idiomsProvider: IdiomsProvider = .shared
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
        case .filterChanged(let filter, let tag):
            filterState = filter
            selectedTag = tag
        }
    }

    private func setupBindings() {
        idiomsProvider.$idioms
            .receive(on: DispatchQueue.main)
            .sink { [weak self] idioms in
                self?.idioms = idioms
                self?.sortIdioms()
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
                title: Loc.Idioms.deleteIdiom.localized,
                message: Loc.Idioms.deleteIdiomConfirmation.localized,
                onCancel: {
                    AnalyticsService.shared.logEvent(.idiomRemovingCanceled)
                },
                onDelete: { [weak self, id] in
                    self?.idiomsProvider.delete(with: id)
                    AnalyticsService.shared.logEvent(.idiomRemoved)
                }
            )
        )
    }

    // MARK: - Computed Properties
    
    var idiomsFiltered: [CDIdiom] {
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
        @unknown default:
            return idioms
        }
    }

    var favoriteIdioms: [CDIdiom] {
        idioms.filter { $0.isFavorite }
    }

    var searchResults: [CDIdiom] {
        idioms.filter { model in
            guard !searchText.isEmpty else { return true }
            return model.idiomItself?.localizedStandardContains(searchText) ?? false
        }
    }

    // MARK: - Difficulty-based filtering

    var newIdioms: [CDIdiom] {
        idioms.filter { $0.difficultyLevel == .new }
    }

    var inProgressIdioms: [CDIdiom] {
        idioms.filter { $0.difficultyLevel == .inProgress }
    }

    var needsReviewIdioms: [CDIdiom] {
        idioms.filter { $0.difficultyLevel == .needsReview }
    }

    var masteredIdioms: [CDIdiom] {
        idioms.filter { $0.difficultyLevel == .mastered }
    }

    // MARK: - Tag-based filtering

    var taggedIdioms: [CDIdiom] {
        guard let selectedTag = selectedTag else { return idioms }
        return idioms.filter { idiom in
            idiom.tagsArray.contains { $0.id == selectedTag.id }
        }
    }

    var availableTags: [CDTag] {
        tagService.tags
    }

    var idiomsCount: String {
        Loc.Idioms.idiomsCount.localized(idiomsFiltered.count)
    }

    var filterStateTitle: String {
        switch filterState {
        case .none:
            return Loc.Idioms.allIdioms.localized
        case .favorite:
            return Loc.Idioms.favoriteIdioms.localized
        case .search:
            return Loc.Idioms.foundIdioms.localized
        case .new:
            return Loc.FilterDisplay.new.localized
        case .inProgress:
            return Loc.FilterDisplay.inProgress.localized
        case .needsReview:
            return Loc.FilterDisplay.needsReview.localized
        case .mastered:
            return Loc.FilterDisplay.mastered.localized
        case .tag:
            return selectedTag?.name ?? Loc.Idioms.idioms.localized
        @unknown default:
            return Loc.Idioms.idioms.localized
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
                (lhs.idiomItself ?? "") < (rhs.idiomItself ?? "")
            })
        case .partOfSpeech:
            break
        }
    }
}
