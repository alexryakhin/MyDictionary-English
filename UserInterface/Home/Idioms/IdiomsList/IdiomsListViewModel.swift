//
//  IdiomsListViewModel.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import Core
import CoreUserInterface
import Services
import Combine

public class IdiomsListViewModel: DefaultPageViewModel {

    enum Input {
        case showAddIdiom
        case showIdiomDetails(idiom: Idiom)
        case deleteIdiom(idiom: Idiom)
    }

    enum Output {
        case showAddIdiom(searchText: String)
        case showIdiomDetails(idiom: Idiom)
    }

    var onOutput: ((Output) -> Void)?

    @Published var idioms: [Idiom] = []
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

    private let idiomsProvider: IdiomsProviderInterface
    private var cancellables = Set<AnyCancellable>()

    public init(idiomsProvider: IdiomsProviderInterface) {
        self.idiomsProvider = idiomsProvider
        super.init()
        loadingStarted()
        setupBindings()
    }

    func handle(_ input: Input) {
        switch input {
        case .showAddIdiom:
            onOutput?(.showAddIdiom(searchText: searchText))
            AnalyticsService.shared.logEvent(.addIdiomTapped)
        case .showIdiomDetails(let idiom):
            onOutput?(.showIdiomDetails(idiom: idiom))
            AnalyticsService.shared.logEvent(.idiomOpened)
        case .deleteIdiom(let idiom):
            deleteIdiom(with: idiom.id)
        }
    }

    private func setupBindings() {
        idiomsProvider.idiomsPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] idioms in
                if idioms.isNotEmpty {
                    self?.idioms = idioms
                    self?.sortIdioms()
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
    var favoriteIdioms: [Idiom] {
        idioms.filter { $0.isFavorite }
    }

    var searchResults: [Idiom] {
        idioms.filter { model in
            guard !searchText.isEmpty else { return true }
            return model.idiom.localizedStandardContains(searchText)
        }
    }

    private func sortIdioms() {
        switch sortingState {
        case .earliest:
            idioms.sort(by: { lhs, rhs in
                lhs.timestamp < rhs.timestamp
            })
        case .latest:
            idioms.sort(by: { lhs, rhs in
                lhs.timestamp > rhs.timestamp
            })
        case .alphabetically:
            idioms.sort(by: { lhs, rhs in
                lhs.idiom < rhs.idiom
            })
        case .partOfSpeech:
            break
        }
    }
}
