import SwiftUI
import Combine
import CoreData

protocol AddWordManagerInterface {

    /// Creates a new word into the Core Data
    func addNewWord(word: String, definition: String, partOfSpeech: String, phonetic: String?, examples: [String], tags: [CDTag], languageCode: String?) throws
}

final class AddWordManager: AddWordManagerInterface {

    private let coreDataService: CoreDataService

    init(coreDataService: CoreDataService) {
        self.coreDataService = coreDataService
    }

    func addNewWord(word: String, definition: String, partOfSpeech: String, phonetic: String?, examples: [String], tags: [CDTag] = [], languageCode: String? = nil) throws {
        let newWord = CDWord(context: coreDataService.context)
        newWord.id = UUID()
        newWord.wordItself = word
        newWord.definition = definition
        newWord.partOfSpeech = partOfSpeech
        newWord.phonetic = phonetic
        newWord.languageCode = languageCode
        newWord.timestamp = Date()
        try newWord.updateExamples(examples)
        
        // Add tags to the word
        for tag in tags {
            tag.addToWords(newWord)
        }
        
        try coreDataService.saveContext()
    }
}
