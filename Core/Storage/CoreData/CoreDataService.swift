//
//  CoreDataService.swift
//  PureBite
//
//  Created by Aleksandr Riakhin on 8/25/24.
//

import CoreData

protocol CoreDataServiceInterface {
    var context: NSManagedObjectContext { get }
    func saveContext() throws(CoreError)
}

class CoreDataService: CoreDataServiceInterface {
    init() {}

    private lazy var persistentContainer: NSPersistentCloudKitContainer = {
        let container = NSPersistentCloudKitContainer(name: "My_Dictionary")
        container.loadPersistentStores { description, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        return container
    }()

    var context: NSManagedObjectContext {
        return persistentContainer.viewContext
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
}
