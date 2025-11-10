//
//  WordCollectionImportService.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 1/27/25.
//

import Foundation
import CoreData

struct WordCollectionImportResult {
    let addedCount: Int
    let duplicateCount: Int
    let addedWords: [String]
}

final class WordCollectionImportService {
    
    static let shared = WordCollectionImportService()
    
    private let addWordManager: AddWordManager = .shared
    private let wordsProvider: WordsProvider = .shared
    private let coreDataService: CoreDataService = .shared
    
    private init() {}
    
    /// Imports words from a word collection
    /// - Parameters:
    ///   - collection: The word collection to import from
    ///   - selectedWordIds: Set of word IDs to import (empty set means import all)
    /// - Returns: ImportResult with counts of added and duplicate words
    func importWords(from collection: WordCollection, selectedWordIds: Set<String> = []) async throws -> WordCollectionImportResult {
        return try await performImport(collection: collection, selectedWordIds: selectedWordIds)
    }
    
    /// Imports all words from a collection (for "Add All" functionality)
    func importAllWords(from collection: WordCollection) async throws -> WordCollectionImportResult {
        return try await importWords(from: collection, selectedWordIds: [])
    }
    
    private func performImport(collection: WordCollection, selectedWordIds: Set<String>) async throws -> WordCollectionImportResult {
        // Get words to import
        let wordsToImport: [WordCollectionItem]
        if selectedWordIds.isEmpty {
            wordsToImport = collection.words
        } else {
            wordsToImport = collection.words.filter { selectedWordIds.contains($0.id) }
        }
        
        // Get existing words to check for duplicates
        let existingWords = try getExistingWords()
        let existingWordTexts = Set(existingWords.map { $0.lowercased() })
        
        // Filter out duplicates and prepare words for import
        let wordsToAdd = wordsToImport.filter { wordItem in
            let wordText = wordItem.text.lowercased()
            return !existingWordTexts.contains(wordText)
        }
        
        let duplicateCount = wordsToImport.count - wordsToAdd.count
        
        // Batch create all words in the same context
        try await createWordsBatch(wordsToAdd: wordsToAdd, collection: collection)
        
        let addedWordTexts = wordsToAdd.map { $0.text }
        
        return WordCollectionImportResult(
            addedCount: wordsToAdd.count,
            duplicateCount: duplicateCount,
            addedWords: addedWordTexts
        )
    }
    
    private func getExistingWords() throws -> [String] {
        let request = CDWord.fetchRequest()
        request.propertiesToFetch = ["wordItself"]
        
        let words = try coreDataService.context.fetch(request)
        return words.compactMap { $0.wordItself }
    }
    
    private func createWordsBatch(wordsToAdd: [WordCollectionItem], collection: WordCollection) async throws {
        let context = coreDataService.context
        
        try await context.perform {
            // Create all words and meanings in the same context
            for wordItem in wordsToAdd {
                let newWord = CDWord(context: context)
                newWord.id = UUID()
                newWord.wordItself = wordItem.text
                newWord.partOfSpeech = wordItem.partOfSpeech.rawValue
                newWord.phonetic = wordItem.phonetics
                newWord.languageCode = collection.languageCode
                newWord.notes = "\(Loc.WordCollections.fromCollection) \(collection.title)"
                newWord.timestamp = Date()
                newWord.updatedAt = Date()
                newWord.isSynced = false
                
                // Create meaning for the word using the proper create method
                let meaning = try CDMeaning.create(
                    in: context,
                    definition: wordItem.definition,
                    examples: wordItem.examples,
                    order: 0,
                    for: newWord
                )
                
                // Add meaning to word (this sets up the bidirectional relationship)
                newWord.addToMeanings(meaning)
            }
            
            // Save context once after creating all words
            try context.save()
        }
    }
}
