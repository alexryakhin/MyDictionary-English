//
//  WordCollectionImportService.swift
//  My Dictionary
//
//  Created by AI Assistant on 1/27/25.
//

import Foundation
import CoreData

struct WordCollectionImportResult {
    let addedCount: Int
    let duplicateCount: Int
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
        return try await withCheckedThrowingContinuation { continuation in
            Task {
                do {
                    let result = try await performImport(collection: collection, selectedWordIds: selectedWordIds)
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
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
        
        var addedCount = 0
        var duplicateCount = 0
        
        // Import each word
        for wordItem in wordsToImport {
            let wordText = wordItem.text.lowercased()
            
            if existingWordTexts.contains(wordText) {
                duplicateCount += 1
                continue
            }
            
            try await addWordToDictionary(wordItem: wordItem, collection: collection)
            addedCount += 1
        }
        
        return WordCollectionImportResult(addedCount: addedCount, duplicateCount: duplicateCount)
    }
    
    private func getExistingWords() throws -> [String] {
        let request = CDWord.fetchRequest()
        request.propertiesToFetch = ["wordItself"]
        
        let words = try coreDataService.context.fetch(request)
        return words.compactMap { $0.wordItself }
    }
    
    private func addWordToDictionary(wordItem: WordCollectionItem, collection: WordCollection) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            Task {
                do {
                    // Create word directly in Core Data to avoid context issues
                    let context = coreDataService.context
                    
                    let newWord = CDWord(context: context)
                    newWord.id = UUID()
                    newWord.wordItself = wordItem.text
                    newWord.partOfSpeech = wordItem.partOfSpeech.rawValue
                    newWord.phonetic = wordItem.phonetics
                    newWord.languageCode = collection.languageCode
                    newWord.notes = "From collection \(collection.title)"
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
                    
                    // Add meaning to word
                    newWord.addToMeanings(meaning)
                    
                    // Save context
                    try context.save()
                    
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
