import SwiftUI
import Combine
import CoreData

final class WordsProvider: ObservableObject {

    @Published var words: [CDWord] = []
    let wordsErrorPublisher = PassthroughSubject<CoreError, Never>()

    private let coreDataService: CoreDataService
    private var cancellables = Set<AnyCancellable>()

    init(coreDataService: CoreDataService) {
        self.coreDataService = coreDataService
        setupBindings()
        fetchWords()
    }

    /// Fetches latest data from Core Data
    func fetchWords() {
        let request = NSFetchRequest<CDWord>(entityName: "Word")
        do {
            let words = try coreDataService.context.fetch(request)
            self.words = words
        } catch {
            wordsErrorPublisher.send(.storageError(.readFailed))
        }
    }

    /// Removes a given word from the Core Data
    func delete(with id: String) {
        let fetchRequest: NSFetchRequest<CDWord> = CDWord.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", id)

        do {
            if let object = try coreDataService.context.fetch(fetchRequest).first {
                coreDataService.context.delete(object)
                try coreDataService.saveContext()
                // Manually refresh the words list after deletion
                fetchWords()
            } else {
                throw CoreError.internalError(.removingWordFailed)
            }
        } catch {
            wordsErrorPublisher.send(.internalError(.removingWordFailed))
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
