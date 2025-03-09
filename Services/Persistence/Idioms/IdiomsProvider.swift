import SwiftUI
import Combine
import CoreData
import Core

public protocol IdiomsProviderInterface {
    var idiomsPublisher: AnyPublisher<[Idiom], Never> { get }
    var idiomsErrorPublisher: AnyPublisher<CoreError, Never> { get }

    /// Fetches latest data from Core Data
    func fetchIdioms()
}

public final class IdiomsProvider: IdiomsProviderInterface {

    public var idiomsPublisher: AnyPublisher<[Idiom], Never> {
        _idiomsPublisher.eraseToAnyPublisher()
    }

    public var idiomsErrorPublisher: AnyPublisher<CoreError, Never> {
        _idiomsErrorPublisher.eraseToAnyPublisher()
    }

    private let _idiomsPublisher = CurrentValueSubject<[Idiom], Never>([])
    private let _idiomsErrorPublisher = PassthroughSubject<CoreError, Never>()
    private let coreDataService: CoreDataServiceInterface
    private var cancellable = Set<AnyCancellable>()

    public init(coreDataService: CoreDataServiceInterface) {
        self.coreDataService = coreDataService
        setupBindings()
        fetchIdioms()
    }

    /// Fetches latest data from Core Data
    public func fetchIdioms() {
        let request = NSFetchRequest<CDIdiom>(entityName: "Idiom")
        do {
            let idioms = try coreDataService.context.fetch(request)
            _idiomsPublisher.send(idioms.compactMap(\.coreModel))
        } catch {
            _idiomsErrorPublisher.send(.storageError(.readFailed))
        }
    }

    private func setupBindings() {
        // every time core data gets updated, call fetchIdioms()
        NotificationCenter.default.mergeChangesObjectIDsPublisher
            .combineLatest(NotificationCenter.default.coreDataDidSavePublisher)
            .sink { [weak self] _ in
                self?.fetchIdioms()
            }
            .store(in: &cancellable)
    }
}
