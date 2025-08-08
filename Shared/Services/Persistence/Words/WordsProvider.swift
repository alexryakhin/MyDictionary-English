import SwiftUI
import Combine
import CoreData

final class WordsProvider: ObservableObject {

    static let shared = WordsProvider()

    @Published var words: [CDWord] = []
    @Published var sharedWords: [CDWord] = []

    private let coreDataService: CoreDataService = .shared
    private let authenticationService = AuthenticationService.shared
    private var cancellables = Set<AnyCancellable>()

    private init() {
        setupBindings()
        fetchWords()
    }

    /// Fetches latest data from Core Data
    func fetchWords() {
        let request = CDWord.fetchRequest()
        let allWords = (try? coreDataService.context.fetch(request)) ?? []
        print("📊 [WordsProvider]Fetched \(allWords.count) total words")

        // Filter words owned by current user (both private and shared)
        self.words = allWords.filter { $0.ownerId == authenticationService.userId }

        // Filter shared words (words in shared dictionaries)
        self.sharedWords = allWords.filter { $0.isSharedWord }

        print("📊 [WordsProvider] Fetched \(self.words.count) owned words and \(self.sharedWords.count) shared words")
    }
    
    /// Fetches shared words for a specific dictionary
    func fetchSharedWords(for dictionaryId: String) -> [CDWord] {
        let request = CDWord.fetchRequest()
        request.predicate = NSPredicate(format: "sharedDictionaryId == %@", dictionaryId)
        
        do {
            let sharedWords = try coreDataService.context.fetch(request)
            print("📊 [WordsProvider] Fetched \(sharedWords.count) shared words for dictionary: \(dictionaryId)")
            return sharedWords
        } catch {
            print("❌ [WordsProvider] Failed to fetch shared words: \(error.localizedDescription)")
            return []
        }
    }
    
    /// Updates shared words for a specific dictionary
    func updateSharedWords(for dictionaryId: String) {
        let sharedWords = fetchSharedWords(for: dictionaryId)
        DispatchQueue.main.async {
            // Update the sharedWords array with the new data
            self.sharedWords = sharedWords
            print("📊 [WordsProvider] Updated shared words for dictionary \(dictionaryId): \(sharedWords.count) words")
        }
    }

    /// Removes a word with given ID from the Core Data
    func deleteWord(with id: String) throws {
        let fetchRequest = CDWord.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", id)

        guard let word = try? coreDataService.context.fetch(fetchRequest).first else {
            print("❌ [WordDetails] No word found with ID \(id)")
            return
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
                self?.fetchWords()
            }
            .store(in: &cancellables)
        
        // Also listen to real-time updates from DataSyncService
        DataSyncService.shared.realTimeUpdateReceived
            .sink { [weak self] _ in
                self?.fetchWords()
            }
            .store(in: &cancellables)
    }
}
