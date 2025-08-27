//
//  JSONImportExportService.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 2/19/25.
//

import Foundation
import CoreData

// MARK: - JSON Data Models

struct VocabularyExport: Codable {
    let version: String
    let exportDate: Date
    let totalWords: Int
    let totalMeanings: Int
    let words: [WordExportData]
    
    init(words: [WordExportData]) {
        self.version = "2.0"
        self.exportDate = Date()
        self.words = words
        self.totalWords = words.count
        self.totalMeanings = words.reduce(0) { $0 + $1.meanings.count }
    }
}

struct WordExportData: Codable, Identifiable {
    let id: String
    let wordItself: String
    let phonetic: String?
    let partOfSpeech: String
    let languageCode: String
    let isFavorite: Bool
    let difficultyScore: Int
    let timestamp: Date
    let updatedAt: Date?
    let meanings: [MeaningExportData]
    let tags: [String]
    
    init(from word: CDWord) {
        self.id = word.id?.uuidString ?? UUID().uuidString
        self.wordItself = word.wordItself ?? ""
        self.phonetic = word.phonetic
        self.partOfSpeech = word.partOfSpeech ?? "unknown"
        self.languageCode = word.languageCode ?? "en"
        self.isFavorite = word.isFavorite
        self.difficultyScore = Int(word.difficultyScore)
        self.timestamp = word.timestamp ?? Date()
        self.updatedAt = word.updatedAt
        self.meanings = word.meaningsArray.map { MeaningExportData(from: $0) }
        self.tags = word.tagsArray.compactMap { $0.name }
    }
}

struct MeaningExportData: Codable, Identifiable {
    let id: String
    let definition: String
    let examples: [String]
    let order: Int
    let timestamp: Date?
    
    init(from meaning: CDMeaning) {
        self.id = meaning.id?.uuidString ?? UUID().uuidString
        self.definition = meaning.definition ?? ""
        self.examples = meaning.examplesDecoded
        self.order = Int(meaning.order)
        self.timestamp = meaning.timestamp
    }
}

// MARK: - Legacy Support Models

struct LegacyWordData: Codable {
    let wordItself: String
    let definition: String
    let partOfSpeech: String
    let phonetic: String?
    let examples: [String]
    let tags: [String]
    let languageCode: String?
    let isFavorite: Bool
    let difficultyScore: Int
    let timestamp: Date
}

// MARK: - Import/Export Service

final class JSONImportExportService {
    
    static let shared = JSONImportExportService()
    
    private let coreDataService = CoreDataService.shared
    private let addWordManager = AddWordManager.shared
    private let tagService = TagService.shared
    
    private init() {}
    
    // MARK: - Export
    
    /// Exports all vocabulary to JSON format
    func exportVocabulary() throws -> Data {
        logInfo("🔄 Starting vocabulary export to JSON")
        
        let fetchRequest = CDWord.fetchRequest()
        let words = try coreDataService.context.fetch(fetchRequest)
        
        let exportWords = words.map { WordExportData(from: $0) }
        let vocabularyExport = VocabularyExport(words: exportWords)
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        let jsonData = try encoder.encode(vocabularyExport)
        
        logInfo("✅ Exported \(words.count) words with \(vocabularyExport.totalMeanings) meanings to JSON")
        return jsonData
    }
    
    /// Exports vocabulary for a specific language
    func exportVocabulary(for languageCode: String) throws -> Data {
        logInfo("🔄 Starting vocabulary export for language: \(languageCode)")
        
        let fetchRequest = CDWord.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "languageCode == %@", languageCode)
        
        let words = try coreDataService.context.fetch(fetchRequest)
        let exportWords = words.map { WordExportData(from: $0) }
        let vocabularyExport = VocabularyExport(words: exportWords)
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        return try encoder.encode(vocabularyExport)
    }
    
    /// Exports only expressions (idioms/phrases)
    func exportExpressions() throws -> Data {
        logInfo("🔄 Starting expressions export to JSON")
        
        let fetchRequest = CDWord.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "partOfSpeech == %@ OR partOfSpeech == %@", "idiom", "phrase")
        
        let expressions = try coreDataService.context.fetch(fetchRequest)
        let exportWords = expressions.map { WordExportData(from: $0) }
        let vocabularyExport = VocabularyExport(words: exportWords)
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        return try encoder.encode(vocabularyExport)
    }
    
    // MARK: - Import
    
    /// Imports vocabulary from JSON data with automatic format detection
    func importVocabulary(from data: Data, overwriteExisting: Bool = false) throws -> ImportResult {
        logInfo("🔄 Starting vocabulary import from JSON")
        
        // Try to detect format by parsing the JSON
        if let newFormatResult = try? importNewFormat(from: data, overwriteExisting: overwriteExisting) {
            return newFormatResult
        } else if let legacyResult = try? importLegacyFormat(from: data, overwriteExisting: overwriteExisting) {
            return legacyResult
        } else {
            throw ImportError.invalidFormat
        }
    }
    
    /// Imports new JSON format (version 2.0 with multiple meanings)
    private func importNewFormat(from data: Data, overwriteExisting: Bool) throws -> ImportResult {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let vocabularyImport = try decoder.decode(VocabularyExport.self, from: data)
        
        logInfo("📚 Importing \(vocabularyImport.words.count) words from JSON v\(vocabularyImport.version)")
        
        var importedCount = 0
        var skippedCount = 0
        var errorCount = 0
        
        for wordData in vocabularyImport.words {
            do {
                // Check if word already exists
                if !overwriteExisting {
                    let existingWord = try findExistingWord(wordItself: wordData.wordItself, languageCode: wordData.languageCode)
                    if existingWord != nil {
                        skippedCount += 1
                        continue
                    }
                }
                
                // Get or create tags
                let tags = try getOrCreateTags(wordData.tags)
                
                // Import word with multiple meanings
                let meanings = wordData.meanings.map { meaning in
                    MeaningData(definition: meaning.definition, examples: meaning.examples)
                }
                
                try addWordManager.addNewWordWithMeanings(
                    word: wordData.wordItself,
                    partOfSpeech: wordData.partOfSpeech,
                    phonetic: wordData.phonetic,
                    meanings: meanings,
                    tags: tags,
                    languageCode: wordData.languageCode
                )
                
                importedCount += 1
                
                // Log progress every 50 words
                if importedCount % 50 == 0 {
                    logInfo("📈 Import progress: \(importedCount)/\(vocabularyImport.words.count)")
                }
                
            } catch {
                logError("❌ Failed to import word '\(wordData.wordItself)': \(error)")
                errorCount += 1
            }
        }
        
        let result = ImportResult(
            totalWords: vocabularyImport.words.count,
            importedCount: importedCount,
            skippedCount: skippedCount,
            errorCount: errorCount,
            format: .jsonV2
        )
        
        logInfo("✅ Import completed: \(result)")
        return result
    }
    
    /// Imports legacy CSV/simple JSON format
    private func importLegacyFormat(from data: Data, overwriteExisting: Bool) throws -> ImportResult {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        // Try to parse as array of legacy word data
        let legacyWords = try decoder.decode([LegacyWordData].self, from: data)
        
        logInfo("📚 Importing \(legacyWords.count) words from legacy format")
        
        var importedCount = 0
        var skippedCount = 0
        var errorCount = 0
        
        for wordData in legacyWords {
            do {
                // Check if word already exists
                if !overwriteExisting {
                    let existingWord = try findExistingWord(wordItself: wordData.wordItself, languageCode: wordData.languageCode)
                    if existingWord != nil {
                        skippedCount += 1
                        continue
                    }
                }
                
                // Get or create tags
                let tags = try getOrCreateTags(wordData.tags)
                
                // Import as single meaning
                try addWordManager.addNewWord(
                    word: wordData.wordItself,
                    definition: wordData.definition,
                    partOfSpeech: wordData.partOfSpeech,
                    phonetic: wordData.phonetic,
                    examples: wordData.examples,
                    tags: tags,
                    languageCode: wordData.languageCode
                )
                
                importedCount += 1
                
            } catch {
                logError("❌ Failed to import legacy word '\(wordData.wordItself)': \(error)")
                errorCount += 1
            }
        }
        
        let result = ImportResult(
            totalWords: legacyWords.count,
            importedCount: importedCount,
            skippedCount: skippedCount,
            errorCount: errorCount,
            format: .legacy
        )
        
        logInfo("✅ Legacy import completed: \(result)")
        return result
    }
    
    // MARK: - Helper Methods
    
    private func findExistingWord(wordItself: String, languageCode: String?) throws -> CDWord? {
        let fetchRequest = CDWord.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "wordItself == %@ AND languageCode == %@", 
                                           wordItself, languageCode ?? "en")
        fetchRequest.fetchLimit = 1
        
        let results = try coreDataService.context.fetch(fetchRequest)
        return results.first
    }
    
    private func getOrCreateTags(_ tagNames: [String]) throws -> [CDTag] {
        var tags: [CDTag] = []
        
        for tagName in tagNames {
            if let existingTag = tagService.tags.first(where: { tag in
                tag.name == tagName
            }) {
                tags.append(existingTag)
            } else {
                let _ = try tagService.createTag(name: tagName, color: .blue)
            }
        }
        
        return tags
    }
}

// MARK: - Supporting Types

struct ImportResult: CustomStringConvertible {
    let totalWords: Int
    let importedCount: Int
    let skippedCount: Int
    let errorCount: Int
    let format: ImportFormat
    
    var description: String {
        return "ImportResult(total: \(totalWords), imported: \(importedCount), skipped: \(skippedCount), errors: \(errorCount), format: \(format))"
    }
}

enum ImportFormat {
    case jsonV2
    case legacy
    case csv
}

enum ImportError: Error, LocalizedError {
    case invalidFormat
    case fileNotFound
    case invalidData
    case duplicateWord(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidFormat:
            return "Invalid file format. Please use a valid JSON or CSV export file."
        case .fileNotFound:
            return "Import file not found."
        case .invalidData:
            return "Invalid data in import file."
        case .duplicateWord(let word):
            return "Duplicate word found: \(word)"
        }
    }
}
