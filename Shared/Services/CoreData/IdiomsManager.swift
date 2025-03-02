import SwiftUI
import Combine
import CoreData
import Swinject
import SwinjectAutoregistration

protocol IdiomsManagerInterface {
    /// Creates a new idiom into the Core Data (does not save the data)
    func addNewIdiom(_ idiom: String, definition: String)

    /// Removes a given idiom from the Core Data (does not save the data)
    func deleteIdiom(_ idiom: Idiom)

    /// Saves all changes in the Core Data
    func saveContext() throws
}

final class IdiomsManager: IdiomsManagerInterface {
    private let coreDataContainer = CoreDataContainer.shared

    func addNewIdiom(_ text: String, definition: String) {
        let newIdiom = Idiom(context: coreDataContainer.viewContext)
        newIdiom.id = UUID()
        newIdiom.idiomItself = text
        newIdiom.definition = definition
        newIdiom.timestamp = Date()
    }

    func deleteIdiom(_ idiom: Idiom) {
        coreDataContainer.viewContext.delete(idiom)
    }

    func saveContext() throws {
        try coreDataContainer.viewContext.save()
    }
}
