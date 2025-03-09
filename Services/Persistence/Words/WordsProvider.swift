import SwiftUI
import Combine
import CoreData
import Core

public protocol WordsProviderInterface {
    var wordsPublisher: AnyPublisher<[Word], Never> { get }
    var wordsErrorPublisher: AnyPublisher<CoreError, Never> { get }

    /// Fetches latest data from Core Data
    func fetchWords()
    /// Removes a given word from the Core Data
    func delete(with id: UUID) throws
}

public final class WordsProvider: WordsProviderInterface {

    public var wordsPublisher: AnyPublisher<[Word], Never> {
        _wordsPublisher.eraseToAnyPublisher()
    }

    public var wordsErrorPublisher: AnyPublisher<CoreError, Never> {
        _wordsErrorPublisher.eraseToAnyPublisher()
    }

    private let _wordsPublisher = CurrentValueSubject<[Word], Never>([])
    private let _wordsErrorPublisher = PassthroughSubject<CoreError, Never>()
    private let coreDataService: CoreDataServiceInterface
    private var cancellable = Set<AnyCancellable>()

    public init(coreDataService: CoreDataServiceInterface) {
        self.coreDataService = coreDataService
        setupBindings()
        fetchWords()
    }

    /// Fetches latest data from Core Data
    public func fetchWords() {
        let request = NSFetchRequest<CDWord>(entityName: "Word")
        do {
            let words = try coreDataService.context.fetch(request)
            _wordsPublisher.send(words.compactMap(\.coreModel))
        } catch {
            _wordsErrorPublisher.send(.storageError(.readFailed))
        }
    }

    /// Removes a given word from the Core Data
    public func delete(with id: UUID) throws {
        let fetchRequest: NSFetchRequest<CDWord> = CDWord.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)

        do {
            if let object = try coreDataService.context.fetch(fetchRequest).first {
                coreDataService.context.delete(object)
                try coreDataService.saveContext()
            } else {
                throw CoreError.internalError(.removingWordFailed)
            }
        } catch {
            throw CoreError.internalError(.removingWordFailed)
        }
    }

    private func setupBindings() {
        // every time core data gets updated, call fetchWords()
        NotificationCenter.default.mergeChangesObjectIDsPublisher
            .combineLatest(NotificationCenter.default.coreDataDidSavePublisher)
            .sink { [weak self] _ in
                self?.fetchWords()
            }
            .store(in: &cancellable)
    }
}
