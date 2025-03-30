import SwiftUI
import Combine
import CoreData
import Core
import Shared

public protocol AddIdiomManagerInterface {

    /// Creates a new idiom into the Core Data (does not save the data)
    func addNewIdiom(_ idiom: String, definition: String) throws(CoreError)
}

public final class AddIdiomManager: AddIdiomManagerInterface {
    private let coreDataService: CoreDataServiceInterface

    public init(coreDataService: CoreDataServiceInterface) {
        self.coreDataService = coreDataService
    }

    public func addNewIdiom(_ text: String, definition: String) throws(CoreError) {
        guard text.isNotEmpty && definition.isNotEmpty else {
            throw CoreError.internalError(.inputCannotBeEmpty)
        }
        let newIdiom = CDIdiom(context: coreDataService.context)
        newIdiom.id = UUID()
        newIdiom.idiomItself = text
        newIdiom.definition = definition
        newIdiom.timestamp = Date()
        try coreDataService.saveContext()
    }
}
