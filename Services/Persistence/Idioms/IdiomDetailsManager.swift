import SwiftUI
import Combine
import CoreData

protocol IdiomDetailsManagerInterface {

    var idiomPublisher: AnyPublisher<Idiom?, Never> { get }
    var errorPublisher: PassthroughSubject<CoreError, Never> { get }

    func updateIdiom(_ idiom: Idiom)
    /// Removes a given idiom from the Core Data
    func deleteIdiom()
}

final class IdiomDetailsManager: IdiomDetailsManagerInterface {

    var idiomPublisher: AnyPublisher<Idiom?, Never> {
        _idiomPublisher.eraseToAnyPublisher()
    }
    let errorPublisher = PassthroughSubject<CoreError, Never>()

    private let coreDataService: CoreDataServiceInterface

    private let _idiomPublisher = CurrentValueSubject<Idiom?, Never>(nil)
    private var cdIdiom: CDIdiom?
    private var cancellables: Set<AnyCancellable> = []

    init(
        idiomId: String,
        coreDataService: CoreDataServiceInterface
    ) {
        self.coreDataService = coreDataService
        fetchIdiom(with: idiomId)
    }

    func updateIdiom(_ idiom: Idiom) {
        cdIdiom?.idiomItself = idiom.idiom
        cdIdiom?.definition = idiom.definition
        cdIdiom?.isFavorite = idiom.isFavorite
        do {
           try cdIdiom?.updateExamples(idiom.examples)
        } catch {
            errorPublisher.send(.internalError(.updatingIdiomExamplesFailed))
        }
        saveContext()
    }

    func deleteIdiom() {
        guard let cdIdiom else { return }
        coreDataService.context.delete(cdIdiom)
        saveContext()
    }

    private func fetchIdiom(with id: String) {
        let fetchRequest: NSFetchRequest<CDIdiom> = CDIdiom.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", id)
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
        } catch {
            errorPublisher.send(.internalError(.removingIdiomFailed))
        }
    }
}
