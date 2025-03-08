import SwiftUI
import Combine
import CoreData
import Core

public protocol WordsManagerInterface {
    /// Creates a new word into the Core Data (does not save the data)
    func addNewWord(word: String, definition: String, partOfSpeech: String, phonetic: String?)

    /// Removes a given word from the Core Data (does not save the data)
    func delete(with id: UUID) throws

    /// Saves all changes in the Core Data
    func saveContext() throws
}

public final class WordsManager: WordsManagerInterface {
    private let coreDataService: CoreDataServiceInterface

    public init(coreDataService: CoreDataServiceInterface) {
        self.coreDataService = coreDataService
    }

    public func addNewWord(word: String, definition: String, partOfSpeech: String, phonetic: String?) {
        let newWord = Word(context: coreDataService.context)
        newWord.id = UUID()
        newWord.wordItself = word
        newWord.definition = definition
        newWord.partOfSpeech = partOfSpeech
        newWord.phonetic = phonetic
        newWord.timestamp = Date()
    }

    public func delete(with id: UUID) throws {
        let fetchRequest: NSFetchRequest<Word> = Word.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)

        do {
            if let object = try coreDataService.context.fetch(fetchRequest).first {
                coreDataService.context.delete(object)
                try coreDataService.context.save()
            } else {
                throw CoreError.internalError(.removingWordFailed)
            }
        } catch {
            throw CoreError.internalError(.removingWordFailed)
        }
    }

    public func saveContext() throws {
        try coreDataService.context.save()
    }
}
