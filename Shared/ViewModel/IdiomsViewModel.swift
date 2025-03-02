import SwiftUI
import Combine
import CoreData

final class IdiomsViewModel: ViewModel {

    @Published var idioms: [Idiom] = []
    @Published var sortingState: SortingCase = .def
    @Published var filterState: FilterCase = .none
    @Published var searchText = ""

    private let idiomsProvider: IdiomsProviderInterface
    private let idiomsManager: IdiomsManagerInterface
    private var cancellables = Set<AnyCancellable>()

    init(
        idiomsProvider: IdiomsProviderInterface,
        idiomsManager: IdiomsManagerInterface
    ) {
        self.idiomsProvider = idiomsProvider
        self.idiomsManager = idiomsManager
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
        idiomsManager.deleteIdiom(idiom)
        saveContext()
    }

    // MARK: Sorting
    var favoriteIdioms: [Idiom] {
        idioms.filter { $0.isFavorite }
    }

    var searchResults: [Idiom] {
        idioms.filter { idiom in
            guard let idiomItself = idiom.idiomItself, !searchText.isEmpty else { return true }
            return idiomItself.localizedStandardContains(searchText)
        }
    }

    func sortIdioms() {
        switch sortingState {
        case .def:
            idioms.sort(by: { lhs, rhs in
                lhs.timestamp ?? .now < rhs.timestamp ?? .now
            })
        case .name:
            idioms.sort(by: { lhs, rhs in
                lhs.idiomItself! < rhs.idiomItself!
            })
        case .partOfSpeech:
            break
        }
    }

    private func saveContext() {
        do {
            try idiomsManager.saveContext()
        } catch {
            handleError(error)
        }
    }
}
