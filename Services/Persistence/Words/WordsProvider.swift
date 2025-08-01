import SwiftUI
import Combine
import CoreData

protocol WordsProviderInterface {
    var wordsPublisher: AnyPublisher<[Word], Never> { get }
    var wordsErrorPublisher: PassthroughSubject<CoreError, Never> { get }

    /// Fetches latest data from Core Data
    func fetchWords()
    /// Removes a given word from the Core Data
    func delete(with id: String)
}

final class WordsProvider: WordsProviderInterface {

    var wordsPublisher: AnyPublisher<[Word], Never> {
        _wordsPublisher.eraseToAnyPublisher()
    }
    let wordsErrorPublisher = PassthroughSubject<CoreError, Never>()

    private let _wordsPublisher = CurrentValueSubject<[Word], Never>([])
    private let coreDataService: CoreDataServiceInterface
    private var cancellables = Set<AnyCancellable>()

    init(coreDataService: CoreDataServiceInterface) {
        self.coreDataService = coreDataService
        setupBindings()
        fetchWords()
    }

    /// Fetches latest data from Core Data
    func fetchWords() {
        let request = NSFetchRequest<CDWord>(entityName: "Word")
        do {
            let words = try coreDataService.context.fetch(request)
            _wordsPublisher.send(words.compactMap(\.coreModel))
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
