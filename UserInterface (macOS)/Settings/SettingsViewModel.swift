import SwiftUI
import Combine
import StoreKit
import Core
import Services
import CoreUserInterface__macOS_
import Shared

final class SettingsViewModel: DefaultPageViewModel {
    @AppStorage(UDKeys.isShowingRating) var isShowingRating: Bool = true

    @Published var exportWordsUrl: URL?
    @Published var isImporting = false
    @Published var importFileURL: URL?

    private let wordsProvider: WordsProviderInterface
    private let csvManager: CSVManagerInterface

    private var words: [Word] = []
    private var cancellables: Set<AnyCancellable> = []

    override init() {
        self.wordsProvider = DIContainer.shared.resolver.resolve(WordsProviderInterface.self)!
        self.csvManager = DIContainer.shared.resolver.resolve(CSVManagerInterface.self)!
        super.init()
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
            exportWordsUrl = csvManager.exportWordsToCSV(wordModels: words)
        }
    }

    func importWords(from url: URL) {
        do {
            try csvManager.importWordsFromCSV(
                url: url,
                currentWordIds: words.compactMap(\.id)
            )
        } catch {
            errorReceived(error, displayType: .alert)
        }
    }
}
