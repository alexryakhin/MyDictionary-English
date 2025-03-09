import SwiftUI
import Combine
import CoreData
import Core

public protocol IdiomsManagerInterface {
    /// Creates a new idiom into the Core Data (does not save the data)
    func addNewIdiom(_ idiom: String, definition: String)

    /// Removes a given idiom from the Core Data (does not save the data)
    func deleteIdiom(with id: UUID) throws

    /// Saves all changes in the Core Data
    func saveContext() throws
}

public final class IdiomsManager: IdiomsManagerInterface {
    private let coreDataService: CoreDataServiceInterface

    public init(coreDataService: CoreDataServiceInterface) {
        self.coreDataService = coreDataService
    }

    public func addNewIdiom(_ text: String, definition: String) {
        let newIdiom = CDIdiom(context: coreDataService.context)
        newIdiom.id = UUID()
        newIdiom.idiomItself = text
        newIdiom.definition = definition
        newIdiom.timestamp = Date()
    }

    public func deleteIdiom(with id: UUID) throws {
        let fetchRequest: NSFetchRequest<CDIdiom> = CDIdiom.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)

        do {
            if let object = try coreDataService.context.fetch(fetchRequest).first {
                coreDataService.context.delete(object)
                try coreDataService.context.save()
            } else {
                throw CoreError.internalError(.removingIdiomFailed)
            }
        } catch {
            throw CoreError.internalError(.removingIdiomFailed)
        }
    }

    public func saveContext() throws {
        try coreDataService.context.save()
    }
}
