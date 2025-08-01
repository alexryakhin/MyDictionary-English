//
//  IdiomsListViewModel.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import Foundation
import Combine

@MainActor
final class IdiomsListViewModel: BaseViewModel {

    enum Input {
        case deleteIdiom(idiom: CDIdiom)
    }

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

    private let idiomsProvider: IdiomsProvider
    private var cancellables = Set<AnyCancellable>()

    override init() {
        self.idiomsProvider = ServiceManager.shared.idiomsProvider
        super.init()
        setupBindings()
    }

    func handle(_ input: Input) {
        switch input {
        case .deleteIdiom(let idiom):
            deleteIdiom(with: idiom.id?.uuidString ?? "")
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
            withModel: .init(
                title: "Delete idiom",
                message: "Are you sure you want to delete this idiom?",
                actionText: "Cancel",
                destructiveActionText: "Delete",
                action: {
                    AnalyticsService.shared.logEvent(.idiomRemovingCanceled)
                },
                destructiveAction: { [weak self, id] in
                    self?.idiomsProvider.delete(with: id)
                    AnalyticsService.shared.logEvent(.idiomRemoved)
                }
            )
        )
    }

    // MARK: Sorting
    var favoriteIdioms: [CDIdiom] {
        idioms.filter { $0.isFavorite }
    }

    var searchResults: [CDIdiom] {
        idioms.filter { model in
            guard !searchText.isEmpty else { return true }
            return model.idiomItself?.localizedStandardContains(searchText) ?? false
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
