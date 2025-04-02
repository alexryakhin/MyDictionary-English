import SwiftUI
import Combine
import Core
import Services
import CoreUserInterface__macOS_
import Shared

final class IdiomsViewModel: DefaultPageViewModel {

    enum Input {
        // List
        case selectIdiom(id: String)
        case deselectIdiom
        case deleteIdiom(atOffsets: IndexSet)

        // Details
        case updateIdiom(text: String)
        case updateDefinition(definition: String)
        case updateCDIdiom
        case play(text: String?)
        case deleteCurrentIdiom
        case toggleFavorite
        case addExample(String)
        case updateExample(at: Int, text: String)
        case removeExample(at: Int)
    }

    @Published var searchText = ""
    @Published var filterState: FilterCase = .none
    @Published var sortingState: SortingCase = .latest {
        didSet {
            sortIdioms()
        }
    }

    @Published private(set) var idioms: [Idiom] = []
    @Published private(set) var selectedIdiom: Idiom?
    @Published private(set) var selectedIdiomId: String? {
        didSet {
            if let selectedIdiomId {
                idiomDetailsManager = DIContainer.shared.resolver.resolve(IdiomDetailsManagerInterface.self, argument: selectedIdiomId)!
            } else {
                idiomDetailsManager = nil
            }
        }
    }

    private let idiomsProvider: IdiomsProviderInterface
    private let ttsPlayer: TTSPlayerInterface
    private var idiomDetailsManager: IdiomDetailsManagerInterface? {
        didSet {
            if let idiomDetailsManager {
                idiomDetailsSubscription = idiomDetailsManager.idiomPublisher
                    .receive(on: DispatchQueue.main)
                    .sink { [weak self] idiom in
                        self?.selectedIdiom = idiom
                        AnalyticsService.shared.logEvent(.idiomOpened)
                    }
            } else {
                idiomDetailsSubscription = nil
                selectedIdiom = nil
            }
        }
    }
    private var cancellables = Set<AnyCancellable>()
    private var idiomDetailsSubscription: AnyCancellable?

    override init() {
        self.idiomsProvider = DIContainer.shared.resolver.resolve(IdiomsProviderInterface.self)!
        self.ttsPlayer = DIContainer.shared.resolver.resolve(TTSPlayerInterface.self)!
        super.init()
        setupBindings()
    }

    func handle(_ input: Input) {
        switch input {
        // MARK: List
        case .selectIdiom(let id):
            Task { @MainActor in
                selectedIdiomId = id
            }
        case .deselectIdiom:
            selectedIdiomId = nil
        case .deleteIdiom(let offsets):
            deleteIdiom(atOffsets: offsets)

        // MARK: Details
        case .updateIdiom(let idiomText):
            selectedIdiom?.idiom = idiomText
        case .updateDefinition(let definition):
            selectedIdiom?.definition = definition
        case .updateCDIdiom:
            updateCDIdiom()
        case .play(let text):
            play(text)
        case .deleteCurrentIdiom:
            deleteCurrentIdiom()
        case .toggleFavorite:
            toggleFavorite()
        case .addExample(let example):
            addExample(example: example)
        case .updateExample(let index, let example):
            updateExample(index: index, example: example)
        case .removeExample(let index):
            removeExample(index: index)
        }
    }

    private func setupBindings() {
        idiomsProvider.idiomsPublisher
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

    private func updateIdioms(_ idioms: [Idiom]) {
        self.idioms = idioms
        sortIdioms()
        if let selectedIdiom = idioms.first(where: { $0.id == selectedIdiomId }) {
            self.selectedIdiom = selectedIdiom
        } else {
            selectedIdiom = nil
        }
    }

    private func deleteIdiom(atOffsets offsets: IndexSet) {
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
    private func deleteIdiom(_ idiom: Idiom, completion: VoidHandler? = nil) {
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
                    self?.idiomsProvider.delete(with: idiom.id)
                    AnalyticsService.shared.logEvent(.idiomRemoved)
                    completion?()
                }
            )
        )
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
        @unknown default:
            fatalError("Unknown sorting state")
        }
    }
}

// MARK: - Details
private extension IdiomsViewModel {
    func updateCDIdiom() {
        if let selectedIdiom {
            idiomDetailsManager?.updateIdiom(selectedIdiom)
        }
    }

    func addExample(example: String) {
        guard !example.isEmpty else {
            errorReceived(CoreError.internalError(.inputCannotBeEmpty), displayType: .alert)
            return
        }
        selectedIdiom?.examples.append(example)
        updateCDIdiom()
        AnalyticsService.shared.logEvent(.idiomExampleAdded)
    }

    func updateExample(index: Int, example: String) {
        guard !example.isEmpty else {
            errorReceived(CoreError.internalError(.inputCannotBeEmpty), displayType: .alert)
            return
        }
        selectedIdiom?.examples[index] = example
        updateCDIdiom()
        AnalyticsService.shared.logEvent(.idiomExampleUpdated)
    }

    func removeExample(index: Int) {
        selectedIdiom?.examples.remove(at: index)
        updateCDIdiom()
        AnalyticsService.shared.logEvent(.idiomExampleRemoved)
    }

    func play(_ text: String?) {
        Task {
            if let text {
                do {
                    try await ttsPlayer.play(text)
                } catch {
                    errorReceived(error, displayType: .alert)
                }
            }
        }
    }

    func deleteCurrentIdiom() {
        guard let selectedIdiom else { return }
        deleteIdiom(selectedIdiom) { [weak self] in
            self?.selectedIdiom = nil
        }
    }

    func toggleFavorite() {
        selectedIdiom?.isFavorite.toggle()
        updateCDIdiom()
    }
}
