import SwiftUI
import Combine
import CoreData

final class WordsProvider: ObservableObject {

    static let shared = WordsProvider()

    @Published var words: [CDWord] = []
    let wordsErrorPublisher = PassthroughSubject<CoreError, Never>()

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
        do {
            let words = try coreDataService.context.fetch(request)
            self.words = words
        } catch {
            wordsErrorPublisher.send(.storageError(.readFailed))
        }
    }

    /// Removes a word with given ID from the Core Data
    func deleteWord(with id: String) {
        let fetchRequest = CDWord.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", id)

        do {
            guard let word = try coreDataService.context.fetch(fetchRequest).first else {
                throw CoreError.internalError(.removingWordFailed)
            }

            // Delete from Firestore for real-time updates
            if authenticationService.isSignedIn, let userId = authenticationService.userId {
                DataSyncService.shared.deleteWordFromFirestore(wordId: id, userId: userId) { [weak self] result in
                    switch result {
                    case .success:
                        print("✅ [WordDetails] Word deleted from Firestore immediately")
                        // Delete from Core Data
                        self?.coreDataService.context.delete(word)
                        try? self?.coreDataService.saveContext()
                        AnalyticsService.shared.logEvent(.wordRemoved)
                    case .failure(let error):
                        AlertCenter.shared.showAlert(with: .error(
                            title: "Word deletion failed",
                            message: error.localizedDescription
                        ))
                        print("❌ [WordDetails] Failed to delete word from Firestore: \(error.localizedDescription)")
                    }
                }
            } else {
                // Delete from Core Data
                coreDataService.context.delete(word)
                try coreDataService.saveContext()
                AnalyticsService.shared.logEvent(.wordRemoved)
            }
        } catch {
            AlertCenter.shared.showAlert(with: .error(
                title: "Word deletion failed",
                message: error.localizedDescription
            ))
        }
    }

    private func setupBindings() {
        coreDataService.dataUpdatedPublisher
            .sink { [weak self] _ in
                self?.fetchWords()
            }
            .store(in: &cancellables)
    }
}
