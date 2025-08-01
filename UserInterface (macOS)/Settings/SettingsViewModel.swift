import SwiftUI
import Combine
import StoreKit

final class SettingsViewModel: BaseViewModel {
    @AppStorage(UDKeys.isShowingRating) var isShowingRating: Bool = true
    @AppStorage(UDKeys.selectedTTSLanguage) var selectedTTSLanguage: TTSLanguage = .enUS

    @Published var exportWordsUrl: URL?
    @Published var isImporting = false
    @Published var importFileURL: URL?

    private let wordsProvider: WordsProviderInterface
    private let csvManager: CSVManagerInterface

    private var words: [Word] = []
    private var cancellables: Set<AnyCancellable> = []

    override init() {
        self.wordsProvider = ServiceManager.shared.wordsProvider
        self.csvManager = ServiceManager.shared.csvManager
        super.init()
        setupBindings()
    }

    private func setupBindings() {
        wordsProvider.wordsPublisher
            .receive(on: RunLoop.main)
            .assign(to: \.words, on: self)
            .store(in: &cancellables)
    }

    func importWords(from url: URL) {
        guard url.startAccessingSecurityScopedResource() else {
            errorReceived(CoreError.internalError(.cannotAccessSecurityScopedResource), displayType: .alert)
            return
        }
        defer { url.stopAccessingSecurityScopedResource() }

        do {
            try csvManager.importWordsFromCSV(
                url: url,
                currentWordIds: words.compactMap(\.id)
            )
            showAlert(withModel: .init(title: "Import Successful", message: "Words imported successfully"))
        } catch {
            errorReceived(error, displayType: .alert)
        }
    }

    func exportWords() {
        guard !words.isEmpty else { return }

        let panel = NSSavePanel()
        panel.allowedContentTypes = [.commaSeparatedText]
        panel.nameFieldStringValue = "Words.csv"
        panel.canCreateDirectories = true
        panel.isExtensionHidden = false
        panel.title = "Export Words"

        Task { @MainActor in
            let response = await panel.begin()
            let tempURL = csvManager.exportWordsToCSV(wordModels: words)
            guard response == .OK, let url = panel.url, let tempURL else { return }
            do {
                guard url.startAccessingSecurityScopedResource() else {
                    throw CoreError.internalError(.cannotAccessSecurityScopedResource)
                }
                defer { url.stopAccessingSecurityScopedResource() }

                try FileManager.default.copyItem(at: tempURL, to: url)
                showAlert(withModel: .init(title: "Export Successful", message: "Words exported successfully."))
            } catch {
                errorReceived(error, displayType: .alert)
            }
        }
    }
}
