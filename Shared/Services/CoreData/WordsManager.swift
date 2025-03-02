import SwiftUI
import Combine
import CoreData
import Swinject
import SwinjectAutoregistration

protocol WordsManagerInterface {
    /// Creates a new word into the Core Data (does not save the data)
    func addNewWord(word: String, definition: String, partOfSpeech: String, phonetic: String?)

    /// Removes a given word from the Core Data (does not save the data)
    func delete(word: Word)

    /// Saves all changes in the Core Data
    func saveContext() throws
}

final class WordsManager: WordsManagerInterface {
    private let coreDataContainer = CoreDataContainer.shared

    func addNewWord(word: String, definition: String, partOfSpeech: String, phonetic: String?) {
        let newWord = Word(context: coreDataContainer.viewContext)
        newWord.id = UUID()
        newWord.wordItself = word
        newWord.definition = definition
        newWord.partOfSpeech = partOfSpeech
        newWord.phonetic = phonetic
        newWord.timestamp = Date()
    }

    func delete(word: Word) {
        coreDataContainer.viewContext.delete(word)
    }

    func saveContext() throws {
        try coreDataContainer.viewContext.save()
    }
}
