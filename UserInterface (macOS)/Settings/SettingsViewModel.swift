import SwiftUI
import Combine
import StoreKit

final class SettingsViewModel: ObservableObject {
//    @AppStorage(UDKeys.isShowingRating) var isShowingRating: Bool = true
//
//    @Published var exportWordsUrl: URL?
//    @Published var isImporting = false
//    @Published var importFileURL: URL?

//    private let coreDataContainer = CoreDataContainer.shared
//    private let wordsProvider: WordsProviderInterface
//
//    private var words: [Word] = []
//    private var cancellables: Set<AnyCancellable> = []

//    override init() {
//        self.wordsProvider = WordsProvider.shared
//        super.init()
//        setupBindings()
//    }

//    private func setupBindings() {
//        wordsProvider.wordsPublisher
//            .receive(on: RunLoop.main)
//            .assign(to: \.words, on: self)
//            .store(in: &cancellables)
//    }

//    func exportWords() {
//        guard !words.isEmpty else { return }
//        Task { @MainActor in
//            exportWordsUrl = CSVManager.shared.exportWordsToCSV(words: words)
//        }
//    }
//
//    func importWords(from url: URL) {
//        do {
//            try CSVManager.shared.importWordsFromCSV(
//                url: url,
//                currentWordIds: words.compactMap(\.id).map(\.uuidString),
//                context: coreDataContainer.viewContext
//            )
//        } catch {
//            handleError(error)
//        }
//    }
}
