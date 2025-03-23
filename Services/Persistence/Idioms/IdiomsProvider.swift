import SwiftUI
import Combine
import CoreData
import Core

public protocol IdiomsProviderInterface {
    var idiomsPublisher: AnyPublisher<[Idiom], Never> { get }
    var idiomsErrorPublisher: PassthroughSubject<CoreError, Never> { get }

    /// Fetches latest data from Core Data
    func fetchIdioms()
    /// Removes a given idiom from the Core Data
    func delete(with id: String)
}

public final class IdiomsProvider: IdiomsProviderInterface {

    public var idiomsPublisher: AnyPublisher<[Idiom], Never> {
        _idiomsPublisher.eraseToAnyPublisher()
    }

    public let idiomsErrorPublisher = PassthroughSubject<CoreError, Never>()

    private let _idiomsPublisher = CurrentValueSubject<[Idiom], Never>([])
    private let coreDataService: CoreDataServiceInterface
    private var cancellables = Set<AnyCancellable>()

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
            idiomsErrorPublisher.send(.storageError(.readFailed))
        }
    }

    /// Removes a given idiom from the Core Data
    public func delete(with id: String) {
        let fetchRequest: NSFetchRequest<CDIdiom> = CDIdiom.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", id)

        do {
            if let object = try coreDataService.context.fetch(fetchRequest).first {
                coreDataService.context.delete(object)
                try coreDataService.saveContext()
            } else {
                throw CoreError.internalError(.removingIdiomFailed)
            }
        } catch {
            idiomsErrorPublisher.send(.internalError(.removingIdiomFailed))
        }
    }

    private func setupBindings() {
        coreDataService.dataUpdatedPublisher
            .sink { [weak self] _ in
                self?.fetchIdioms()
            }
            .store(in: &cancellables)
    }
}
