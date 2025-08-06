import SwiftUI
import Combine
import CoreData

final class AddIdiomManager {

    static let shared = AddIdiomManager()

    private let coreDataService: CoreDataService = .shared

    private init() {}

    func addNewIdiom(_ text: String, definition: String) throws(CoreError) {
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
