//
//  CoreDataService.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import CoreData
import Core

public protocol CoreDataServiceInterface {
    var context: NSManagedObjectContext { get }
    func saveContext() throws(CoreError)
}

public class CoreDataService: CoreDataServiceInterface {
    public init() {}

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

    public var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }

    public func saveContext() throws(CoreError) {
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
