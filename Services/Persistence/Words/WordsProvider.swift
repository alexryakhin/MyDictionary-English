import SwiftUI
import Combine
import CoreData
import Core

public protocol WordsProviderInterface {
    var wordsPublisher: AnyPublisher<[Word], Never> { get }
    var wordsErrorPublisher: PassthroughSubject<CoreError, Never> { get }

    /// Fetches latest data from Core Data
    func fetchWords()
    /// Removes a given word from the Core Data
    func delete(with id: UUID)
}

public final class WordsProvider: WordsProviderInterface {

    public var wordsPublisher: AnyPublisher<[Word], Never> {
        _wordsPublisher.eraseToAnyPublisher()
    }
    public let wordsErrorPublisher = PassthroughSubject<CoreError, Never>()

    private let _wordsPublisher = CurrentValueSubject<[Word], Never>([])
    private let coreDataService: CoreDataServiceInterface
    private var cancellables = Set<AnyCancellable>()

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
            wordsErrorPublisher.send(.storageError(.readFailed))
        }
    }

    /// Removes a given word from the Core Data
    public func delete(with id: UUID) {
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
            wordsErrorPublisher.send(.internalError(.removingWordFailed))
        }
    }

    private func setupBindings() {
        NotificationCenter.default.eventChangedPublisher
            .combineLatest(NotificationCenter.default.coreDataDidSaveObjectIDsPublisher)
            .debounce(for: .seconds(0.3), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.fetchWords()
            }
            .store(in: &cancellables)
    }
}
