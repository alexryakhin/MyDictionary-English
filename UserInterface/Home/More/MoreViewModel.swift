import Core
import CoreUserInterface
import CoreNavigation
import Services
import Shared
import Combine
import SwiftUI

public final class MoreViewModel: DefaultPageViewModel {

    enum Input {
        case showAboutApp
    }

    enum Output {
        case showAboutApp
    }

    var onOutput: ((Output) -> Void)?

    @AppStorage(UDKeys.selectedTTSLanguage) var selectedTTSLanguage: TTSLanguage = .enUS

    @Published var isImporting = false
    @Published var importFileURL: URL?
    @Published var exportWordsUrl: URL?

    private let wordsProvider: WordsProviderInterface
    private let csvManager: CSVManagerInterface

    private var words: [Word] = []
    private var cancellables: Set<AnyCancellable> = []

    public init(
        wordsProvider: WordsProviderInterface,
        csvManager: CSVManagerInterface
    ) {
        self.wordsProvider = wordsProvider
        self.csvManager = csvManager
        super.init()
        setupBindings()
    }

    func handle(_ input: Input) {
        switch input {
        case .showAboutApp:
            onOutput?(.showAboutApp)
        }
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
