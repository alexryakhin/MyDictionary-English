import SwiftUI
import Combine

final class IdiomsViewModel: BaseViewModel {

    @Published var searchText = ""
    @Published var filterState: FilterCase = .none
    @Published var sortingState: SortingCase = .latest {
        didSet {
            sortIdioms()
        }
    }

    @Published private(set) var idioms: [CDIdiom] = []
    @Published var selectedIdiom: CDIdiom?

    private let idiomsProvider: IdiomsProvider
    private let ttsPlayer: TTSPlayer
    private let coreDataService: CoreDataService
    // No longer need idiomDetailsManager since we work directly with Core Data objects
    private var cancellables = Set<AnyCancellable>()
    private var idiomDetailsSubscription: AnyCancellable?

    override init() {
        self.idiomsProvider = ServiceManager.shared.idiomsProvider
        self.ttsPlayer = ServiceManager.shared.ttsPlayer
        self.coreDataService = CoreDataService.shared
        super.init()
        setupBindings()
    }

    private func setupBindings() {
        idiomsProvider.$idioms
            .receive(on: DispatchQueue.main)
            .sink { [weak self] idioms in
                self?.updateIdioms(idioms)
            }
            .store(in: &cancellables)

        // React to the search input from a user
        $searchText
            .sink { [weak self] value in
                self?.filterState = value.isEmpty ? .none : .search
            }
            .store(in: &cancellables)
    }

    private func updateIdioms(_ idioms: [CDIdiom]) {
        self.idioms = idioms
        sortIdioms()
        if let selectedIdiom = idioms.first(where: { $0.id?.uuidString == selectedIdiom?.id?.uuidString }) {
            self.selectedIdiom = selectedIdiom
        } else {
            selectedIdiom = nil
        }
    }

    func deleteIdiom(atOffsets offsets: IndexSet) {
        switch filterState {
        case .none:
            offsets.map { idioms[$0] }.forEach { [weak self] idiom in
                self?.deleteIdiom(idiom)
            }
        case .favorite:
            offsets.map { favoriteIdioms[$0] }.forEach { [weak self] idiom in
                self?.deleteIdiom(idiom)
            }
        case .search:
            offsets.map { searchResults[$0] }.forEach { [weak self] idiom in
                self?.deleteIdiom(idiom)
            }
        @unknown default:
            fatalError("Unsupported filter state")
        }
    }

    /// Removes given word from Core Data
    private func deleteIdiom(_ idiom: CDIdiom, completion: VoidHandler? = nil) {
        showAlert(
            withModel: .init(
                title: "Delete idiom",
                message: "Are you sure you want to delete this idiom?",
                actionText: "Cancel",
                destructiveActionText: "Delete",
                action: {
                    AnalyticsService.shared.logEvent(.idiomRemovingCanceled)
                },
                destructiveAction: { [weak self] in
                    self?.idiomsProvider.delete(with: idiom.id?.uuidString ?? "")
                    AnalyticsService.shared.logEvent(.idiomRemoved)
                    completion?()
                }
            )
        )
    }

    // MARK: Sorting
    var favoriteIdioms: [CDIdiom] {
        idioms.filter { $0.isFavorite }
    }

    var searchResults: [CDIdiom] {
        idioms.filter { idiom in
            guard !searchText.isEmpty else { return true }
            return idiom.idiomItself?.localizedStandardContains(searchText) ?? false
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
        @unknown default:
            fatalError("Unknown sorting state")
        }
    }
}
