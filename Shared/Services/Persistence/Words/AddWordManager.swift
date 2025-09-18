import SwiftUI
import Combine
import CoreData

final class AddWordManager {

    static let shared = AddWordManager()

    private let coreDataService: CoreDataService = .shared
    private let authenticationService: AuthenticationService = .shared

    private init() {}

    /// Adds a new word with a single meaning (legacy method for backward compatibility)
    func addNewWord(word: String, definition: String, partOfSpeech: String, phonetic: String?, examples: [String], tags: [CDTag] = [], languageCode: String? = nil, imageUrl: String? = nil, imageLocalPath: String? = nil) throws {
        try addNewWordWithMeanings(
            word: word,
            partOfSpeech: partOfSpeech,
            phonetic: phonetic,
            meanings: [MeaningData(definition: definition, examples: examples)],
            tags: tags,
            languageCode: languageCode,
            imageUrl: imageUrl,
            imageLocalPath: imageLocalPath
        )
    }
    
    /// Adds a new word with multiple meanings
    func addNewWordWithMeanings(
        word: String,
        partOfSpeech: String,
        phonetic: String? = nil,
        meanings: [MeaningData],
        tags: [CDTag] = [],
        languageCode: String? = nil,
        imageUrl: String? = nil,
        imageLocalPath: String? = nil
    ) throws {
        print("🔍 [AddWordManager] addNewWordWithMeanings called with word: '\(word)'")
        
        guard !meanings.isEmpty else {
            throw CoreError.internalError(.inputCannotBeEmpty)
        }
        
        let newWord = CDWord(context: coreDataService.context)
        newWord.id = UUID()
        newWord.wordItself = word
        newWord.partOfSpeech = partOfSpeech
        newWord.phonetic = phonetic
        newWord.languageCode = languageCode
        newWord.timestamp = Date()
        newWord.isSynced = false // Mark as not synced initially
        newWord.imageUrl = imageUrl
        newWord.imageLocalPath = imageLocalPath
        print("📝 [AddWordManager] Created CDWord with id: \(newWord.id?.uuidString ?? "nil")")
        
        // Add meanings
        for (index, meaningData) in meanings.enumerated() {
            let meaning = try CDMeaning.create(
                in: coreDataService.context,
                definition: meaningData.definition,
                examples: meaningData.examples,
                order: Int32(index),
                for: newWord
            )
            newWord.addToMeanings(meaning)
        }
        print("📝 [AddWordManager] Added \(meanings.count) meanings")
        
        // Add tags to the word
        for tag in tags {
            tag.addToWords(newWord)
        }
        print("📝 [AddWordManager] Added \(tags.count) tags")
        
        print("💾 [AddWordManager] Saving to Core Data")
        try coreDataService.saveContext()
        print("✅ [AddWordManager] Word saved to Core Data successfully")
    }
    
    /// Adds a new expression (idiom or phrase)
    func addNewExpression(
        expression: String,
        partOfSpeech: PartOfSpeech, // Should be .idiom or .phrase
        definition: String,
        examples: [String] = [],
        tags: [CDTag] = [],
        languageCode: String? = nil
    ) throws {
        guard partOfSpeech.isExpression else {
            throw CoreError.storageError(.saveFailed)
        }
        
        try addNewWordWithMeanings(
            word: expression,
            partOfSpeech: partOfSpeech.rawValue,
            phonetic: nil, // Expressions typically don't have phonetic info
            meanings: [MeaningData(definition: definition, examples: examples)],
            tags: tags,
            languageCode: languageCode
        )
    }
    
    /// Updates an existing word with new meanings
    func updateWordMeanings(_ word: CDWord, meanings: [MeaningData]) throws {
        // Remove existing meanings
        let existingMeanings = word.meaningsArray
        for meaning in existingMeanings {
            word.removeFromMeanings(meaning)
            coreDataService.context.delete(meaning)
        }
        
        // Add new meanings
        for (index, meaningData) in meanings.enumerated() {
            let meaning = try CDMeaning.create(
                in: coreDataService.context,
                definition: meaningData.definition,
                examples: meaningData.examples,
                order: Int32(index),
                for: word
            )
            word.addToMeanings(meaning)
        }
        
        word.updatedAt = Date()
        word.isSynced = false
        
        try coreDataService.saveContext()
        print("✅ [AddWordManager] Word meanings updated successfully")
    }
    
    /// Adds a meaning to an existing word
    func addMeaningToWord(_ word: CDWord, definition: String, examples: [String] = []) throws {
        let meaning = try word.addMeaning(definition: definition, examples: examples)
        
        word.updatedAt = Date()
        word.isSynced = false
        
        try coreDataService.saveContext()
        print("✅ [AddWordManager] Meaning added to word: \(word.wordItself ?? "unknown")")
    }
    
    /// Removes a meaning from a word
    func removeMeaningFromWord(_ word: CDWord, meaning: CDMeaning) throws {
        // Don't allow removing the last meaning
        guard word.meaningsArray.count > 1 else {
            throw CoreError.storageError(.saveFailed)
        }
        
        word.removeMeaning(meaning)
        word.updatedAt = Date()
        word.isSynced = false
        
        // Reorder remaining meanings
        word.reorderMeanings()
        
        try coreDataService.saveContext()
        print("✅ [AddWordManager] Meaning removed from word: \(word.wordItself ?? "unknown")")
    }
}

// MARK: - Data Structures

struct MeaningData {
    let definition: String
    let examples: [String]
    
    init(definition: String, examples: [String] = []) {
        self.definition = definition
        self.examples = examples
    }
}
