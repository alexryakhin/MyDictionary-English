//
//  IdiomsListViewModel.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import Core
import CoreUserInterface
import CoreNavigation
import Services
import Combine

public class IdiomsListViewModel: DefaultPageViewModel {

    enum Input {
        case showAddIdiom
        case showIdiomDetails(idiom: Idiom)
    }

    enum Output {
        case showAddIdiom(searchText: String)
        case showIdiomDetails(idiom: Idiom)
    }

    var onOutput: ((Output) -> Void)?

    @Published var idioms: [Idiom] = []
    @Published var sortingState: SortingCase = .def
    @Published var filterState: FilterCase = .none
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
        case .showIdiomDetails(let idiom):
            onOutput?(.showIdiomDetails(idiom: idiom))
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

    // MARK: Removing from CD
    func deleteIdiom(atOffsets offsets: IndexSet) {
        switch filterState {
        case .none:
            offsets.map { idioms[$0] }.forEach { [weak self] idiom in
                self?.deleteIdiom(with: idiom.id)
            }
        case .favorite:
            offsets.map { favoriteIdioms[$0] }.forEach { [weak self] idiom in
                self?.deleteIdiom(with: idiom.id)
            }
        case .search:
            offsets.map { searchResults[$0] }.forEach { [weak self] idiom in
                self?.deleteIdiom(with: idiom.id)
            }
        }
    }

    /// Removes given idiom from Core Data
    func deleteIdiom(with id: UUID) {
        idiomsProvider.delete(with: id)
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

    func sortIdioms() {
        switch sortingState {
        case .def:
            idioms.sort(by: { lhs, rhs in
                lhs.timestamp < rhs.timestamp
            })
        case .name:
            idioms.sort(by: { lhs, rhs in
                lhs.idiom < rhs.idiom
            })
        case .partOfSpeech:
            break
        }
    }
}
