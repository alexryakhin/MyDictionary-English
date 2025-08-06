import SwiftUI
import Combine
import CoreData

final class IdiomsProvider: ObservableObject {

    static let shared = IdiomsProvider()

    @Published var idioms: [CDIdiom] = []
    let idiomsErrorPublisher = PassthroughSubject<CoreError, Never>()

    private let coreDataService: CoreDataService = .shared
    private var cancellables = Set<AnyCancellable>()

    private init() {
        setupBindings()
        fetchIdioms()
    }

    /// Fetches latest data from Core Data
    func fetchIdioms() {
        let request = CDIdiom.fetchRequest()
        do {
            let idioms = try coreDataService.context.fetch(request)
            self.idioms = idioms
        } catch {
            idiomsErrorPublisher.send(.storageError(.readFailed))
        }
    }

    /// Removes a given idiom from the Core Data
    func delete(with id: String) {
        let fetchRequest = CDIdiom.fetchRequest()
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
