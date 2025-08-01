//
//  CoreDataService.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import CoreData
import Combine

final class CoreDataService {

    static let shared = CoreDataService()

    let dataUpdatedPublisher = PassthroughSubject<Void, Never>()

    var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }

    private lazy var persistentContainer: NSPersistentCloudKitContainer = {
        let container = NSPersistentCloudKitContainer(name: "My_Dictionary")
        let description = container.persistentStoreDescriptions.first
        description?.shouldMigrateStoreAutomatically = true
        description?.shouldInferMappingModelAutomatically = true

        container.loadPersistentStores { description, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy
        return container
    }()

    private var cancellables: Set<AnyCancellable> = []

    private init() {
        setupBindings()
    }

    func saveContext() throws(CoreError) {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                throw .storageError(.saveFailed)
            }
        }
    }

    private func setupBindings() {
        NotificationCenter.default.eventChangedPublisher
            .combineLatest(NotificationCenter.default.coreDataDidSaveObjectIDsPublisher)
            .debounce(for: .seconds(0.3), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.dataUpdatedPublisher.send()
            }
            .store(in: &cancellables)
    }
}
