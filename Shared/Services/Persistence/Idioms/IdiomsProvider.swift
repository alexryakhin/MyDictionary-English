import SwiftUI
import Combine
import CoreData

final class IdiomsProvider: ObservableObject {

    @Published var idioms: [CDIdiom] = []
    let idiomsErrorPublisher = PassthroughSubject<CoreError, Never>()

    private let coreDataService: CoreDataService
    private var cancellables = Set<AnyCancellable>()

    init(coreDataService: CoreDataService) {
        self.coreDataService = coreDataService
        setupBindings()
        fetchIdioms()
    }

    /// Fetches latest data from Core Data
    func fetchIdioms() {
        let request = NSFetchRequest<CDIdiom>(entityName: "Idiom")
        do {
            let idioms = try coreDataService.context.fetch(request)
            self.idioms = idioms
        } catch {
            idiomsErrorPublisher.send(.storageError(.readFailed))
        }
    }

    /// Removes a given idiom from the Core Data
    func delete(with id: String) {
        let fetchRequest: NSFetchRequest<CDIdiom> = CDIdiom.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", id)

        do {
            if let object = try coreDataService.context.fetch(fetchRequest).first {
                coreDataService.context.delete(object)
                try coreDataService.saveContext()
                // Manually refresh the idioms list after deletion
                fetchIdioms()
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
