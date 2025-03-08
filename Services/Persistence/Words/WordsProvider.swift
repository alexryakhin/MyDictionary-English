import SwiftUI
import Combine
import CoreData
import Core

public protocol WordsProviderInterface {
    var wordsPublisher: AnyPublisher<[CoreWord], Never> { get }
    var wordsErrorPublisher: AnyPublisher<CoreError, Never> { get }

    /// Fetches latest data from Core Data
    func fetchWords()
}

public final class WordsProvider: WordsProviderInterface {

    public var wordsPublisher: AnyPublisher<[CoreWord], Never> {
        _wordsPublisher.eraseToAnyPublisher()
    }

    public var wordsErrorPublisher: AnyPublisher<CoreError, Never> {
        _wordsErrorPublisher.eraseToAnyPublisher()
    }

    private let _wordsPublisher = CurrentValueSubject<[CoreWord], Never>([])
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
        let request = NSFetchRequest<Word>(entityName: "Word")
        do {
            let words = try coreDataService.context.fetch(request)
            _wordsPublisher.send(words.compactMap(\.coreModel))
        } catch {
            _wordsErrorPublisher.send(.storageError(.readFailed))
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
