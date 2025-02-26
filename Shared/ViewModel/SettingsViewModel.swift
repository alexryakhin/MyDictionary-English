import SwiftUI
import Combine
import StoreKit

final class SettingsViewModel: ObservableObject {
    @AppStorage(UDKeys.isShowingRating) var isShowingRating: Bool = true
    @AppStorage(UDKeys.isShowingIdioms) var isShowingIdioms: Bool = false

    @Published var exportWordsUrl: URL?
    @Published var isImporting = false
    @Published var importFileURL: URL?

    private let coreDataContainer: CoreDataContainerInterface
    private let wordsProvider: WordsProviderInterface

    private var words: [Word] = []
    private var cancellables: Set<AnyCancellable> = []

    init(
        wordsProvider: WordsProviderInterface,
        coreDataContainer: CoreDataContainerInterface
    ) {
        self.wordsProvider = wordsProvider
        self.coreDataContainer = coreDataContainer
        setupBindings()
    }

    private func setupBindings() {
        wordsProvider.wordsPublisher
            .receive(on: RunLoop.main)
            .assign(to: \.words, on: self)
            .store(in: &cancellables)
    }

    func exportWords() {
        guard !words.isEmpty else { return }
        Task { @MainActor in
            exportWordsUrl = CSVManager.shared.exportWordsToCSV(words: words)
        }
    }

    func importWords(from url: URL) {
        do {
            try CSVManager.shared.importWordsFromCSV(
                url: url,
                currentWordIds: words.compactMap(\.id).map(\.uuidString),
                context: coreDataContainer.viewContext
            )
        } catch {
            // TODO: show error
            print(error)
        }
    }
}
