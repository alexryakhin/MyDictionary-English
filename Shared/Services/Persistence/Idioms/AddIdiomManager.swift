import SwiftUI
import Combine
import CoreData

final class AddIdiomManager {

    static let shared = AddIdiomManager()

    private let coreDataService: CoreDataService = .shared

    private init() {}

    func addNewIdiom(_ text: String, definition: String, languageCode: String? = "en", tags: [CDTag] = []) throws(CoreError) {
        guard text.isNotEmpty && definition.isNotEmpty else {
            throw CoreError.internalError(.inputCannotBeEmpty)
        }
        let newIdiom = CDIdiom(context: coreDataService.context)
        newIdiom.id = UUID()
        newIdiom.idiomItself = text
        newIdiom.definition = definition
        newIdiom.difficultyScore = 0 // Initialize with new difficulty
        newIdiom.languageCode = languageCode
        newIdiom.timestamp = Date()
        
        // Add tags to the idiom
        for tag in tags {
            newIdiom.addToTags(tag)
        }
        
        try coreDataService.saveContext()
    }
}
