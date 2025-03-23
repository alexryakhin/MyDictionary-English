import SwiftUI
import Combine
import CoreData
import Core

public protocol AddWordManagerInterface {

    /// Creates a new word into the Core Data
    func addNewWord(word: String, definition: String, partOfSpeech: String, phonetic: String?, examples: [String]) throws
}

public final class AddWordManager: AddWordManagerInterface {

    private let coreDataService: CoreDataServiceInterface

    public init(coreDataService: CoreDataServiceInterface) {
        self.coreDataService = coreDataService
    }

    public func addNewWord(word: String, definition: String, partOfSpeech: String, phonetic: String?, examples: [String]) throws {
        let newWord = CDWord(context: coreDataService.context)
        newWord.id = UUID()
        newWord.wordItself = word
        newWord.definition = definition
        newWord.partOfSpeech = partOfSpeech
        newWord.phonetic = phonetic
        newWord.timestamp = Date()
        try newWord.updateExamples(examples)
        try coreDataService.saveContext()
    }
}
