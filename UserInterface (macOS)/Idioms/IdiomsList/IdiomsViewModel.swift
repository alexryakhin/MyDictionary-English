import SwiftUI
import Combine
import Core
import Services
import CoreUserInterface__macOS_
import Shared

final class IdiomsViewModel: DefaultPageViewModel {

    @Published var idioms: [Idiom] = []
    @Published var sortingState: SortingCase = .def
    @Published var filterState: FilterCase = .none
    @Published var searchText = ""

    private let idiomsProvider: IdiomsProviderInterface
    private var cancellables = Set<AnyCancellable>()

    override init() {
        self.idiomsProvider = DIContainer.shared.resolver.resolve(IdiomsProviderInterface.self)!
        super.init()
        setupBindings()
    }

    private func setupBindings() {
        idiomsProvider.idiomsPublisher
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

    // MARK: Removing from CD
    func deleteIdiom(atOffsets offsets: IndexSet) {
        switch filterState {
        case .none:
            withAnimation {
                offsets.map { idioms[$0] }.forEach { [weak self] idiom in
                    self?.deleteIdiom(idiom)
                }
            }
        case .favorite:
            withAnimation {
                offsets.map { favoriteIdioms[$0] }.forEach { [weak self] idiom in
                    self?.deleteIdiom(idiom)
                }
            }
        case .search:
            withAnimation {
                offsets.map { searchResults[$0] }.forEach { [weak self] idiom in
                    self?.deleteIdiom(idiom)
                }
            }
        }
    }

    /// Removes given word from Core Data
    func deleteIdiom(_ idiom: Idiom) {
        idiomsProvider.delete(with: idiom.id)
    }

    // MARK: Sorting
    var favoriteIdioms: [Idiom] {
        idioms.filter { $0.isFavorite }
    }

    var searchResults: [Idiom] {
        idioms.filter { idiom in
            guard !searchText.isEmpty else { return true }
            return idiom.idiom.localizedStandardContains(searchText)
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
