import SwiftUI
import Combine
import CoreData

final class WordsProvider: ObservableObject {

    static let shared = WordsProvider()

    @Published var words: [CDWord] = []

    private let coreDataService: CoreDataService = .shared
    private let authenticationService = AuthenticationService.shared
    private var cancellables = Set<AnyCancellable>()

    private init() {
        setupBindings()
        try? fetchWords()
    }

    /// Fetches latest data from Core Data
    func fetchWords() throws {
        let request = CDWord.fetchRequest()
        words = try coreDataService.context.fetch(request)
        print("✅ [WordDetails] Fetched words from Core Data, count: \(words.count)")
    }

    /// Removes a word with given ID from the Core Data
    func deleteWord(with id: String) throws {
        let fetchRequest = CDWord.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", id)

        guard let word = try? coreDataService.context.fetch(fetchRequest).first else {
            print("❌ [WordDetails] No word found with ID \(id)")
            return
        }
        #if os(macOS)
        if SideBarManager.shared.selectedWord == word {
            SideBarManager.shared.selectedWord = nil
        }
        #endif
        // Manual sync mode - no automatic sync when deleting words
        print("ℹ️ [WordDetails] Manual sync mode - no automatic sync")
        
        // Delete from Core Data
        coreDataService.context.delete(word)
        try? coreDataService.saveContext()
        AnalyticsService.shared.logEvent(.wordRemoved)
    }

    private func setupBindings() {
        coreDataService.dataUpdatedPublisher
            .sink { [weak self] _ in
                try? self?.fetchWords()
            }
            .store(in: &cancellables)
        
        // No real-time updates in manual sync mode
    }
}
