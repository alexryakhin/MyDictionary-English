import SwiftUI
import Combine
import CoreData
import Core

public protocol IdiomDetailsManagerInterface {

    var idiomPublisher: AnyPublisher<Idiom?, Never> { get }
    var errorPublisher: PassthroughSubject<CoreError, Never> { get }

    func toggleFavorite()
    func updateDefinition(_ definition: String)
    func addExample(_ example: String)
    func removeExample(atOffsets offsets: IndexSet)
    /// Removes a given idiom from the Core Data
    func deleteIdiom()
}

public final class IdiomDetailsManager: IdiomDetailsManagerInterface {

    public var idiomPublisher: AnyPublisher<Idiom?, Never> {
        _idiomPublisher.eraseToAnyPublisher()
    }
    public let errorPublisher = PassthroughSubject<CoreError, Never>()

    private let idiomId: UUID
    private let coreDataService: CoreDataServiceInterface

    private let _idiomPublisher = CurrentValueSubject<Idiom?, Never>(nil)
    private var cdIdiom: CDIdiom?
    private var cancellables: Set<AnyCancellable> = []

    public init(
        idiomId: UUID,
        coreDataService: CoreDataServiceInterface
    ) {
        self.idiomId = idiomId
        self.coreDataService = coreDataService
        fetchIdiom()
    }

    public func toggleFavorite() {
        cdIdiom?.isFavorite.toggle()
        saveContext()
    }

    public func updateDefinition(_ definition: String) {
        cdIdiom?.definition = definition
        saveContext()
    }

    public func addExample(_ example: String) {
        do {
            try cdIdiom?.addExample(example)
        } catch {
            errorPublisher.send(.internalError(.savingIdiomExampleFailed))
        }
        saveContext()
    }

    public func removeExample(atOffsets offsets: IndexSet) {
        do {
            try cdIdiom?.removeExample(atOffsets: offsets)
        } catch {
            errorPublisher.send(.internalError(.removingIdiomExampleFailed))
        }
        saveContext()
    }

    public func deleteIdiom() {
        guard let cdIdiom else { return }
        coreDataService.context.delete(cdIdiom)
        saveContext()
    }

    private func fetchIdiom() {
        let fetchRequest: NSFetchRequest<CDIdiom> = CDIdiom.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", idiomId as CVarArg)
        do {
            if let cdIdiom: CDIdiom = try coreDataService.context.fetch(fetchRequest).first {
                self.cdIdiom = cdIdiom
                _idiomPublisher.send(cdIdiom.coreModel)
            }
        } catch {
            errorPublisher.send(.storageError(.readFailed))
        }
    }

    private func saveContext() {
        do {
            try coreDataService.saveContext()
            _idiomPublisher.send(cdIdiom?.coreModel)
        } catch {
            errorPublisher.send(.internalError(.removingIdiomFailed))
        }
    }
}
