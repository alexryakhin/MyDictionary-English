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
        if SideBarManager.shared.selectedWord == word {
            SideBarManager.shared.selectedWord = nil
        }

        // Delete from Firestore for real-time updates
        if authenticationService.isSignedIn, let userId = authenticationService.userId {
            Task {
                do {
                    try await DataSyncService.shared.deleteWordFromFirestore(wordId: id, userId: userId)
                    print("✅ [WordDetails] Word deleted from Firestore immediately")
                    // Delete from Core Data
                    self.coreDataService.context.delete(word)
                    try? self.coreDataService.saveContext()
                    AnalyticsService.shared.logEvent(.wordRemoved)
                } catch {
                    print("❌ [WordDetails] Failed to delete word from Firestore: \(error.localizedDescription)")
                    throw error
                }
            }
        } else {
            // Delete from Core Data
            coreDataService.context.delete(word)
            try? coreDataService.saveContext()
            AnalyticsService.shared.logEvent(.wordRemoved)
        }
    }

    private func setupBindings() {
        coreDataService.dataUpdatedPublisher
            .sink { [weak self] _ in
                try? self?.fetchWords()
            }
            .store(in: &cancellables)
        
        // Also listen to real-time updates from DataSyncService
        DataSyncService.shared.realTimeUpdateReceived
            .sink { [weak self] _ in
                try? self?.fetchWords()
            }
            .store(in: &cancellables)
    }
}
