import SwiftUI
import Combine
import CoreData
import Swinject
import SwinjectAutoregistration

protocol IdiomsProviderInterface {
    var idiomsPublisher: AnyPublisher<[Idiom], Never> { get }
    var idiomsErrorPublisher: AnyPublisher<AppError, Never> { get }

    /// Fetches latest data from Core Data
    func fetchIdioms()
}

final class IdiomsProvider: IdiomsProviderInterface {

    var idiomsPublisher: AnyPublisher<[Idiom], Never> {
        _idiomsPublisher.eraseToAnyPublisher()
    }

    var idiomsErrorPublisher: AnyPublisher<AppError, Never> {
        _idiomsErrorPublisher.eraseToAnyPublisher()
    }

    private let _idiomsPublisher = CurrentValueSubject<[Idiom], Never>([])
    private let _idiomsErrorPublisher = PassthroughSubject<AppError, Never>()
    private let coreDataContainer = CoreDataContainer.shared
    private var cancellable = Set<AnyCancellable>()

    init() {
        setupBindings()
        fetchIdioms()
    }

    /// Fetches latest data from Core Data
    func fetchIdioms() {
        let request = NSFetchRequest<Idiom>(entityName: "Idiom")
        do {
            let idioms = try coreDataContainer.viewContext.fetch(request)
            _idiomsPublisher.send(idioms)
        } catch {
            _idiomsErrorPublisher.send(.coreDataError(.fetchError))
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
