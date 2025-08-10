import SwiftUI
import Combine
import CoreData

final class AddWordManager {

    static let shared = AddWordManager()

    private let coreDataService: CoreDataService = .shared
    private let authenticationService: AuthenticationService = .shared

    private init() {}

    func addNewWord(word: String, definition: String, partOfSpeech: String, phonetic: String?, examples: [String], tags: [CDTag] = [], languageCode: String? = nil) throws {
        print("🔍 [AddWordManager] addNewWord called with word: '\(word)'")
        
        let newWord = CDWord(context: coreDataService.context)
        newWord.id = UUID()
        newWord.wordItself = word
        newWord.definition = definition
        newWord.partOfSpeech = partOfSpeech
        newWord.phonetic = phonetic
        newWord.languageCode = languageCode
        newWord.timestamp = Date()
        newWord.isSynced = false // Mark as not synced initially
        print("📝 [AddWordManager] Created CDWord with id: \(newWord.id?.uuidString ?? "nil")")
        
        try newWord.updateExamples(examples)
        print("📝 [AddWordManager] Updated examples: \(examples)")
        
        // Add tags to the word
        for tag in tags {
            tag.addToWords(newWord)
        }
        print("📝 [AddWordManager] Added \(tags.count) tags")
        
        print("💾 [AddWordManager] Saving to Core Data")
        try coreDataService.saveContext()
        print("✅ [AddWordManager] Word saved to Core Data successfully")
    }
}
