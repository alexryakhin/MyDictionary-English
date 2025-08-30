//
//  DataMigrationService.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 2/19/25.
//

import Foundation
import CoreData
import SwiftUI

enum MigrationPhase: String, CaseIterable {
    case starting = "starting"
    case migratingWordDefinitions = "migrating_word_definitions"
    case migratingIdioms = "migrating_idioms"
    case validating = "validating"
    case cleanup = "cleanup"
    case completed = "completed"
    case failed = "failed"
    
    var displayName: String {
        switch self {
        case .starting: return "Preparing migration..."
        case .migratingWordDefinitions: return "Migrating word definitions..."
        case .migratingIdioms: return "Migrating expressions..."
        case .validating: return "Validating data..."
        case .cleanup: return "Finalizing..."
        case .completed: return "Migration completed!"
        case .failed: return "Migration failed"
        }
    }
}

enum MigrationError: Error, LocalizedError {
    case coreDataContextNotFound
    case migrationAlreadyInProgress
    case migrationFailed(String)
    case validationFailed(String)
    case rollbackFailed(String)
    case insufficientStorage
    
    var errorDescription: String? {
        switch self {
        case .coreDataContextNotFound:
            return "Core Data context not found"
        case .migrationAlreadyInProgress:
            return "Migration is already in progress"
        case .migrationFailed(let message):
            return "Migration failed: \(message)"
        case .validationFailed(let message):
            return "Validation failed: \(message)"
        case .rollbackFailed(let message):
            return "Rollback failed: \(message)"
        case .insufficientStorage:
            return "Insufficient storage space for migration"
        }
    }
}

struct MigrationProgress {
    let phase: MigrationPhase
    let currentItem: Int
    let totalItems: Int
    let message: String
    
    var percentage: Double {
        guard totalItems > 0 else { return 0 }
        return Double(currentItem) / Double(totalItems)
    }
}

@MainActor
final class DataMigrationService: ObservableObject {
    
    static let shared = DataMigrationService()
    
    @Published var isInProgress = false
    @Published var progress = MigrationProgress(phase: .starting, currentItem: 0, totalItems: 1, message: "")
    @Published var error: Error?
    
    private let coreDataService = CoreDataService.shared
    private let userDefaults = UserDefaults.standard
    
    // Migration state keys
    private let migrationCompletedKey = "migrationToVersion2Completed"
    private let migrationVersionKey = "migrationVersion"
    private let lastMigrationDateKey = "lastMigrationDate"
    private let migrationAttemptsKey = "migrationAttempts"
    
    private init() {}
    
    /// Checks if migration is needed
    var needsMigration: Bool {
        return !userDefaults.bool(forKey: migrationCompletedKey)
    }
    
    /// Performs the complete migration process
    func performMigration() async throws {
        guard !isInProgress else {
            throw MigrationError.migrationAlreadyInProgress
        }
        
        await MainActor.run {
            isInProgress = true
            error = nil
            progress = MigrationProgress(phase: .starting, currentItem: 0, totalItems: 1, message: "Preparing migration...")
        }
        
        do {
            // Check available storage
            try await checkAvailableStorage()
            
            // Clean up any existing duplicates before migration
            await MainActor.run {
                progress = MigrationProgress(phase: .starting, currentItem: 0, totalItems: 1, message: "Checking for duplicates...")
            }
            
            let cleanupResult = try detectAndCleanupDuplicates()
            if cleanupResult.totalChanges > 0 {
                logInfo("🧹 Cleaned up \(cleanupResult.totalChanges) duplicates before migration")
            }
            
            // Perform migration phases
            try await migrateWordDefinitions()
            try await migrateIdiomsToWords()
            try await validateMigration()
            try await cleanup()
            
            // Final duplicate cleanup after migration
            await MainActor.run {
                progress = MigrationProgress(phase: .cleanup, currentItem: 0, totalItems: 1, message: "Final duplicate check...")
            }
            
            let finalCleanupResult = try detectAndCleanupDuplicates()
            if finalCleanupResult.totalChanges > 0 {
                logInfo("🧹 Final cleanup: removed \(finalCleanupResult.totalChanges) duplicates after migration")
            }
            
            // Mark migration as completed
            await MainActor.run {
                userDefaults.set(true, forKey: migrationCompletedKey)
                userDefaults.set("2.0", forKey: migrationVersionKey)
                userDefaults.set(Date(), forKey: lastMigrationDateKey)
                userDefaults.set(0, forKey: migrationAttemptsKey)
                
                progress = MigrationProgress(phase: .completed, currentItem: 1, totalItems: 1, message: "Migration completed successfully!")
                isInProgress = false
            }
            
            logInfo("✅ Migration completed successfully")
            
        } catch {
            await MainActor.run {
                self.error = error
                self.progress = MigrationProgress(phase: .failed, currentItem: 0, totalItems: 1, message: error.localizedDescription)
                self.isInProgress = false
                
                // Increment attempt counter
                let attempts = userDefaults.integer(forKey: migrationAttemptsKey) + 1
                userDefaults.set(attempts, forKey: migrationAttemptsKey)
            }
            
            logError("❌ Migration failed: \(error)")
            
            // Attempt rollback
            await rollbackMigration()
            throw error
        }
    }
    
    /// Phase 1: Migrate existing CDWord definitions to CDMeaning entities
    private func migrateWordDefinitions() async throws {
        logInfo("🔄 Starting Phase 1: Migrating word definitions to meanings")
        
        await MainActor.run {
            progress = MigrationProgress(phase: .migratingWordDefinitions, currentItem: 0, totalItems: 1, message: "Loading words...")
        }
        
        let context = coreDataService.context
        let wordFetchRequest = CDWord.fetchRequest()
        // Get all words - we'll filter in the loop to handle edge cases better
        
        let allWords = try context.fetch(wordFetchRequest)
        let totalWords = allWords.count
        
        logInfo("Found \(totalWords) total words to check for migration")
        
        await MainActor.run {
            progress = MigrationProgress(
                phase: .migratingWordDefinitions,
                currentItem: 0,
                totalItems: totalWords,
                message: "Migrating word definitions..."
            )
        }
        
        var migratedCount = 0
        var skippedCount = 0
        
        for (index, word) in allWords.enumerated() {
            // Skip if word already has meanings
            if word.meaningsArray.isEmpty {
                // Create new meaning from existing definition and examples
                let definition = word.definition ?? ""
                let examples = word.examplesDecoded
                
                // Always create a meaning for existing words, even if definition is empty
                // This ensures all existing words have at least one meaning after migration
                let meaning = try CDMeaning.create(
                    in: context,
                    definition: definition.isEmpty ? "No definition available" : definition,
                    examples: examples,
                    order: 0,
                    for: word
                )
                
                word.addToMeanings(meaning)
                migratedCount += 1
                logInfo("Migrated definition for word: \(word.wordItself ?? "unknown") - def: '\(definition.isEmpty ? "[empty]" : String(definition.prefix(50)))...')")
            } else {
                // Word already has meanings, check for duplicates
                let existingDefinitions = Set(word.meaningsArray.compactMap { $0.definition })
                let legacyDefinition = word.definition ?? ""
                
                // Only add legacy definition if it doesn't already exist as a meaning
                if !legacyDefinition.isEmpty && !existingDefinitions.contains(legacyDefinition) {
                    let examples = word.examplesDecoded
                    let meaning = try CDMeaning.create(
                        in: context,
                        definition: legacyDefinition,
                        examples: examples,
                        order: Int32(word.meaningsArray.count), // Add as last meaning
                        for: word
                    )
                    
                    word.addToMeanings(meaning)
                    migratedCount += 1
                    logInfo("Added legacy definition as new meaning for word: \(word.wordItself ?? "unknown")")
                } else {
                    skippedCount += 1
                    logInfo("Skipped duplicate definition for word: \(word.wordItself ?? "unknown")")
                }
            }
            
            // Update progress every 10 words
            if index % 10 == 0 {
                await MainActor.run {
                    progress = MigrationProgress(
                        phase: .migratingWordDefinitions,
                        currentItem: index + 1,
                        totalItems: totalWords,
                        message: "Migrating definitions... (\(index + 1)/\(totalWords))"
                    )
                }
            }
        }
        
        try context.save()
        logInfo("✅ Phase 1 completed: Migrated \(migratedCount) word definitions, skipped \(skippedCount) duplicates out of \(totalWords) total words")
    }
    
    /// Phase 2: Migrate CDIdiom entities to CDWord entities
    private func migrateIdiomsToWords() async throws {
        logInfo("🔄 Starting Phase 2: Migrating idioms to words")
        
        await MainActor.run {
            progress = MigrationProgress(phase: .migratingIdioms, currentItem: 0, totalItems: 1, message: "Loading idioms...")
        }
        
        let context = coreDataService.context
        let idiomFetchRequest = CDIdiom.fetchRequest()
        let idioms = try context.fetch(idiomFetchRequest)
        let totalIdioms = idioms.count
        
        logInfo("Found \(totalIdioms) idioms to migrate")
        
        await MainActor.run {
            progress = MigrationProgress(
                phase: .migratingIdioms,
                currentItem: 0,
                totalItems: totalIdioms,
                message: "Migrating idioms..."
            )
        }
        
        var migratedIdiomCount = 0
        var skippedCount = 0
        
        for (index, idiom) in idioms.enumerated() {
            let idiomText = idiom.idiomItself ?? ""
            
            // Check if this idiom was already migrated by looking for existing CDWord with same text and idiom type
            let existingWordRequest = CDWord.fetchRequest()
            existingWordRequest.predicate = NSPredicate(format: "wordItself == %@ AND partOfSpeech == %@", 
                                                       idiomText, "idiom")
            existingWordRequest.fetchLimit = 1
            
            let existingWords = try context.fetch(existingWordRequest)
            if !existingWords.isEmpty {
                logInfo("Skipping already migrated idiom: \(idiomText)")
                skippedCount += 1
                continue
            }
            
            // Additional check: look for any word with the same text (case-insensitive)
            let duplicateWordRequest = CDWord.fetchRequest()
            duplicateWordRequest.predicate = NSPredicate(format: "wordItself ==[c] %@", idiomText)
            duplicateWordRequest.fetchLimit = 1
            
            let duplicateWords = try context.fetch(duplicateWordRequest)
            if !duplicateWords.isEmpty {
                logInfo("Skipping idiom that already exists as word: \(idiomText)")
                skippedCount += 1
                continue
            }
            
            // Create new CDWord with partOfSpeech = "idiom"
            let newWord = CDWord(context: context)
            newWord.id = UUID()
            newWord.wordItself = idiomText
            newWord.partOfSpeech = "idiom"
            newWord.phonetic = nil // Idioms don't typically have phonetic info
            newWord.languageCode = idiom.languageCode
            newWord.timestamp = idiom.timestamp
            newWord.isFavorite = idiom.isFavorite
            newWord.difficultyScore = idiom.difficultyScore
            newWord.isSynced = false // Mark as not synced since it's a new entity structure
            
            // Create meaning from idiom definition and examples
            let definition = idiom.definition ?? ""
            let examples = idiom.examplesDecoded
            
            let meaning = try CDMeaning.create(
                in: context,
                definition: definition,
                examples: examples,
                order: 0,
                for: newWord
            )
            
            newWord.addToMeanings(meaning)
            
            // Migrate tags relationship
            if let tags = idiom.tags {
                for tag in tags {
                    if let cdTag = tag as? CDTag {
                        newWord.addToTags(cdTag)
                    }
                }
            }
            
            migratedIdiomCount += 1
            logInfo("Migrated idiom: \(idiomText)")
            
            // Update progress every 5 idioms (they're usually fewer)
            if index % 5 == 0 || index == totalIdioms - 1 {
                await MainActor.run {
                    progress = MigrationProgress(
                        phase: .migratingIdioms,
                        currentItem: index + 1,
                        totalItems: totalIdioms,
                        message: "Migrating idioms... (\(index + 1)/\(totalIdioms))"
                    )
                }
            }
        }
        
        try context.save()
        logInfo("✅ Phase 2 completed: Migrated \(migratedIdiomCount) new idioms, skipped \(skippedCount) duplicates out of \(totalIdioms) total idioms")
    }
    
    /// Phase 3: Validate migration success
    private func validateMigration() async throws {
        logInfo("🔍 Starting Phase 3: Validation")
        
        await MainActor.run {
            progress = MigrationProgress(phase: .validating, currentItem: 0, totalItems: 1, message: "Validating migration...")
        }
        
        let context = coreDataService.context
        
        // Check that all words have at least one meaning
        let wordFetchRequest = CDWord.fetchRequest()
        let allWords = try context.fetch(wordFetchRequest)
        
        var wordsWithoutMeanings = 0
        for word in allWords {
            if word.meaningsArray.isEmpty {
                wordsWithoutMeanings += 1
                logError("⚠️ Word without meanings: \(word.wordItself ?? "unknown")")
            }
        }
        
        if wordsWithoutMeanings > 0 {
            throw MigrationError.validationFailed("Found \(wordsWithoutMeanings) words without meanings")
        }
        
        // Check that idioms were successfully converted
        let idiomWords = allWords.filter { $0.partOfSpeechDecoded == .idiom }
        let originalIdiomCount = try context.fetch(CDIdiom.fetchRequest()).count
        
        logInfo("Original idioms: \(originalIdiomCount), Migrated idiom words: \(idiomWords.count)")
        
        // Check data integrity
        let totalWords = allWords.count
        let totalMeanings = try context.fetch(CDMeaning.fetchRequest()).count
        
        logInfo("✅ Validation passed:")
        logInfo("  - Total words: \(totalWords)")
        logInfo("  - Total meanings: \(totalMeanings)")
        logInfo("  - Idiom words: \(idiomWords.count)")
        logInfo("  - Words without meanings: \(wordsWithoutMeanings)")
    }
    
    /// Phase 4: Cleanup - Remove old CDIdiom entities
    private func cleanup() async throws {
        logInfo("🧹 Starting Phase 4: Cleanup")
        
        await MainActor.run {
            progress = MigrationProgress(phase: .cleanup, currentItem: 0, totalItems: 1, message: "Cleaning up...")
        }
        
        let context = coreDataService.context
        
        // Delete all CDIdiom entities since they've been migrated to CDWord
        let idiomFetchRequest = CDIdiom.fetchRequest()
        let idioms = try context.fetch(idiomFetchRequest)
        
        for idiom in idioms {
            context.delete(idiom)
        }
        
        try context.save()
        logInfo("✅ Phase 4 completed: Deleted \(idioms.count) old idiom entities")
    }
    
    /// Checks if there's sufficient storage space for migration
    private func checkAvailableStorage() async throws {
        // Rough estimate: migration might need up to 50% additional space temporarily
        let fileManager = FileManager.default
        guard let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return
        }
        
        do {
            let resourceValues = try documentsPath.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey])
            if let capacity = resourceValues.volumeAvailableCapacityForImportantUsage {
                let availableGB = Double(capacity) / 1_000_000_000
                logInfo("Available storage: \(String(format: "%.2f", availableGB)) GB")
                
                // Require at least 100MB free space for migration
                if capacity < 100_000_000 {
                    throw MigrationError.insufficientStorage
                }
            }
        } catch {
            logWarning("Could not check storage capacity: \(error)")
            // Continue anyway - storage check is not critical
        }
    }
    
    /// Attempts to rollback the migration
    private func rollbackMigration() async {
        logInfo("🔄 Attempting migration rollback")
        // This is a simplified rollback - in practice, you might want to keep a backup
        // For now, we'll just mark migration as failed and let user retry
        await MainActor.run {
            userDefaults.set(false, forKey: migrationCompletedKey)
            let attempts = userDefaults.integer(forKey: migrationAttemptsKey)
            userDefaults.set(attempts + 1, forKey: migrationAttemptsKey)
        }

        logInfo("✅ Migration marked for retry")
    }
    
    /// Resets migration state for testing or retry
    func resetMigrationState() {
        userDefaults.removeObject(forKey: migrationCompletedKey)
        userDefaults.removeObject(forKey: migrationVersionKey)
        userDefaults.removeObject(forKey: lastMigrationDateKey)
        userDefaults.removeObject(forKey: migrationAttemptsKey)
        
        // Reset the UI state as well
        DispatchQueue.main.async {
            self.isInProgress = false
            self.error = nil
            self.progress = MigrationProgress(phase: .starting, currentItem: 0, totalItems: 1, message: "")
        }
        
        logInfo("🔄 Migration state reset - ready for retry")
    }
    
    /// Manually clean up duplicate idiom words (for fixing existing duplicates)
    func cleanupDuplicateIdioms() throws {
        let context = coreDataService.context
        
        // Find all idiom words
        let idiomWordsRequest = CDWord.fetchRequest()
        idiomWordsRequest.predicate = NSPredicate(format: "partOfSpeech == %@", "idiom")
        idiomWordsRequest.sortDescriptors = [NSSortDescriptor(key: "wordItself", ascending: true), 
                                           NSSortDescriptor(key: "timestamp", ascending: true)]
        
        let idiomWords = try context.fetch(idiomWordsRequest)
        var seenWords: Set<String> = []
        var duplicatesToDelete: [CDWord] = []
        
        for word in idiomWords {
            let wordText = word.wordItself ?? ""
            if seenWords.contains(wordText) {
                // This is a duplicate
                duplicatesToDelete.append(word)
                logInfo("Marking duplicate idiom for deletion: \(wordText)")
            } else {
                seenWords.insert(wordText)
            }
        }
        
        // Delete duplicates
        for duplicate in duplicatesToDelete {
            context.delete(duplicate)
        }
        
        try context.save()
        logInfo("✅ Cleaned up \(duplicatesToDelete.count) duplicate idiom words")
    }
    
    /// Public method to manually run duplicate cleanup
    func runDuplicateCleanup() async throws -> DuplicateCleanupResult {
        guard !isInProgress else {
            throw MigrationError.migrationAlreadyInProgress
        }
        
        await MainActor.run {
            isInProgress = true
            error = nil
            progress = MigrationProgress(phase: .cleanup, currentItem: 0, totalItems: 1, message: "Checking for duplicates...")
        }
        
        do {
            let result = try detectAndCleanupDuplicates()
            
            await MainActor.run {
                progress = MigrationProgress(phase: .completed, currentItem: 1, totalItems: 1, message: "Duplicate cleanup completed!")
                isInProgress = false
            }
            
            logInfo("✅ Manual duplicate cleanup completed: \(result.totalChanges) changes made")
            return result
            
        } catch {
            await MainActor.run {
                self.error = error
                self.progress = MigrationProgress(phase: .failed, currentItem: 0, totalItems: 1, message: error.localizedDescription)
                self.isInProgress = false
            }
            
            logError("❌ Duplicate cleanup failed: \(error)")
            throw error
        }
    }
    
    /// Comprehensive duplicate detection and cleanup for all word types
    func detectAndCleanupDuplicates() throws -> DuplicateCleanupResult {
        let context = coreDataService.context
        var result = DuplicateCleanupResult()
        
        logInfo("🔍 Starting comprehensive duplicate detection")
        
        // 1. Find duplicate words by text (case-insensitive)
        let allWordsRequest = CDWord.fetchRequest()
        allWordsRequest.sortDescriptors = [
            NSSortDescriptor(key: "wordItself", ascending: true),
            NSSortDescriptor(key: "timestamp", ascending: true)
        ]
        
        let allWords = try context.fetch(allWordsRequest)
        var wordGroups: [String: [CDWord]] = [:]
        
        // Group words by their lowercase text
        for word in allWords {
            let wordText = word.wordItself ?? ""
            let key = wordText.lowercased()
            if wordGroups[key] == nil {
                wordGroups[key] = []
            }
            wordGroups[key]?.append(word)
        }
        
        // Find groups with more than one word
        for (key, words) in wordGroups {
            if words.count > 1 {
                logInfo("Found \(words.count) duplicate words for text: '\(key)'")
                
                // Keep the oldest word (first by timestamp) and mark others for deletion
                let sortedWords = words.sorted { 
                    ($0.timestamp ?? Date.distantPast) < ($1.timestamp ?? Date.distantPast)
                }
                
                let wordToKeep = sortedWords.first!
                let duplicatesToDelete = Array(sortedWords.dropFirst())
                
                // Merge meanings from duplicates into the word to keep
                for duplicate in duplicatesToDelete {
                    for meaning in duplicate.meaningsArray {
                        // Check if this meaning already exists in the word to keep
                        let existingMeaning = wordToKeep.meaningsArray.first { existing in
                            existing.definition == meaning.definition
                        }
                        
                        if existingMeaning == nil {
                            // Move meaning to the word to keep
                            duplicate.removeFromMeanings(meaning)
                            wordToKeep.addToMeanings(meaning)
                            meaning.word = wordToKeep
                            result.mergedMeanings += 1
                        }
                    }
                    
                    // Merge tags
                    for tag in duplicate.tagsArray {
                        if !wordToKeep.tagsArray.contains(where: { $0.id == tag.id }) {
                            duplicate.removeFromTags(tag)
                            wordToKeep.addToTags(tag)
                            result.mergedTags += 1
                        }
                    }
                    
                    // Keep the favorite status if any duplicate is favorite
                    if duplicate.isFavorite {
                        wordToKeep.isFavorite = true
                    }
                    
                    // Keep the highest difficulty score
                    if duplicate.difficultyScore > wordToKeep.difficultyScore {
                        wordToKeep.difficultyScore = duplicate.difficultyScore
                    }
                    
                    context.delete(duplicate)
                    result.deletedWords += 1
                }
            }
        }
        
        // 2. Find duplicate meanings within the same word
        let wordsWithMultipleMeanings = allWords.filter { $0.meaningsArray.count > 1 }
        
        for word in wordsWithMultipleMeanings {
            var seenDefinitions: Set<String> = []
            var meaningsToDelete: [CDMeaning] = []
            
            for meaning in word.meaningsArray {
                let definition = meaning.definition ?? ""
                if seenDefinitions.contains(definition) {
                    meaningsToDelete.append(meaning)
                    logInfo("Found duplicate meaning for word '\(word.wordItself ?? "")': '\(String(definition.prefix(50)))...'")
                } else {
                    seenDefinitions.insert(definition)
                }
            }
            
            for meaning in meaningsToDelete {
                word.removeFromMeanings(meaning)
                context.delete(meaning)
                result.deletedMeanings += 1
            }
        }
        
        // 3. Find duplicate tags
        let allTagsRequest = CDTag.fetchRequest()
        allTagsRequest.sortDescriptors = [
            NSSortDescriptor(key: "name", ascending: true),
            NSSortDescriptor(key: "timestamp", ascending: true)
        ]
        
        let allTags = try context.fetch(allTagsRequest)
        var tagGroups: [String: [CDTag]] = [:]
        
        for tag in allTags {
            let tagName = tag.name ?? ""
            let key = tagName.lowercased()
            if tagGroups[key] == nil {
                tagGroups[key] = []
            }
            tagGroups[key]?.append(tag)
        }
        
        for (key, tags) in tagGroups {
            if tags.count > 1 {
                logInfo("Found \(tags.count) duplicate tags for name: '\(key)'")
                
                let sortedTags = tags.sorted { 
                    ($0.timestamp ?? Date.distantPast) < ($1.timestamp ?? Date.distantPast)
                }
                
                let tagToKeep = sortedTags.first!
                let duplicatesToDelete = Array(sortedTags.dropFirst())
                
                // Merge word relationships
                for duplicate in duplicatesToDelete {
                    for word in duplicate.wordsArray {
                        duplicate.removeFromWords(word)
                        tagToKeep.addToWords(word)
                    }
                    
                    // Merge idiom relationships (if any still exist)
                    for idiom in duplicate.idiomsArray {
                        duplicate.removeFromIdioms(idiom)
                        tagToKeep.addToIdioms(idiom)
                    }
                    
                    context.delete(duplicate)
                    result.deletedTags += 1
                }
            }
        }
        
        try context.save()
        
        logInfo("✅ Duplicate cleanup completed:")
        logInfo("  - Deleted \(result.deletedWords) duplicate words")
        logInfo("  - Deleted \(result.deletedMeanings) duplicate meanings")
        logInfo("  - Deleted \(result.deletedTags) duplicate tags")
        logInfo("  - Merged \(result.mergedMeanings) meanings")
        logInfo("  - Merged \(result.mergedTags) tag relationships")
        
        return result
    }
    
    /// Result of duplicate cleanup operation
    struct DuplicateCleanupResult {
        var deletedWords: Int = 0
        var deletedMeanings: Int = 0
        var deletedTags: Int = 0
        var mergedMeanings: Int = 0
        var mergedTags: Int = 0
        
        var totalChanges: Int {
            return deletedWords + deletedMeanings + deletedTags + mergedMeanings + mergedTags
        }
    }
    
    /// Returns migration statistics
    var migrationStats: [String: Any] {
        return [
            "completed": userDefaults.bool(forKey: migrationCompletedKey),
            "version": userDefaults.string(forKey: migrationVersionKey) ?? "unknown",
            "lastDate": userDefaults.object(forKey: lastMigrationDateKey) as? Date ?? Date.distantPast,
            "attempts": userDefaults.integer(forKey: migrationAttemptsKey)
        ]
    }
    
    /// Check for duplicates without cleaning them up (for diagnostics)
    func checkForDuplicates() throws -> DuplicateAnalysisResult {
        let context = coreDataService.context
        var result = DuplicateAnalysisResult()
        
        logInfo("🔍 Starting duplicate analysis (read-only)")
        
        // 1. Check for duplicate words by text (case-insensitive)
        let allWordsRequest = CDWord.fetchRequest()
        allWordsRequest.sortDescriptors = [
            NSSortDescriptor(key: "wordItself", ascending: true),
            NSSortDescriptor(key: "timestamp", ascending: true)
        ]
        
        let allWords = try context.fetch(allWordsRequest)
        var wordGroups: [String: [CDWord]] = [:]
        
        // Group words by their lowercase text
        for word in allWords {
            let wordText = word.wordItself ?? ""
            let key = wordText.lowercased()
            if wordGroups[key] == nil {
                wordGroups[key] = []
            }
            wordGroups[key]?.append(word)
        }
        
        // Count groups with more than one word
        for (key, words) in wordGroups {
            if words.count > 1 {
                result.duplicateWords[key] = words
                logInfo("Found \(words.count) duplicate words for text: '\(key)'")
            }
        }
        
        // 2. Check for duplicate meanings within the same word
        let wordsWithMultipleMeanings = allWords.filter { $0.meaningsArray.count > 1 }
        
        for word in wordsWithMultipleMeanings {
            var seenDefinitions: Set<String> = []
            var duplicateMeanings: [CDMeaning] = []
            
            for meaning in word.meaningsArray {
                let definition = meaning.definition ?? ""
                if seenDefinitions.contains(definition) {
                    duplicateMeanings.append(meaning)
                } else {
                    seenDefinitions.insert(definition)
                }
            }
            
            if !duplicateMeanings.isEmpty {
                result.duplicateMeanings[word.wordItself ?? ""] = duplicateMeanings
                logInfo("Found \(duplicateMeanings.count) duplicate meanings for word: '\(word.wordItself ?? "")'")
            }
        }
        
        // 3. Check for duplicate tags
        let allTagsRequest = CDTag.fetchRequest()
        allTagsRequest.sortDescriptors = [
            NSSortDescriptor(key: "name", ascending: true),
            NSSortDescriptor(key: "timestamp", ascending: true)
        ]
        
        let allTags = try context.fetch(allTagsRequest)
        var tagGroups: [String: [CDTag]] = [:]
        
        for tag in allTags {
            let tagName = tag.name ?? ""
            let key = tagName.lowercased()
            if tagGroups[key] == nil {
                tagGroups[key] = []
            }
            tagGroups[key]?.append(tag)
        }
        
        for (key, tags) in tagGroups {
            if tags.count > 1 {
                result.duplicateTags[key] = tags
                logInfo("Found \(tags.count) duplicate tags for name: '\(key)'")
            }
        }
        
        logInfo("✅ Duplicate analysis completed:")
        logInfo("  - Found \(result.duplicateWords.count) groups of duplicate words")
        logInfo("  - Found \(result.duplicateMeanings.count) words with duplicate meanings")
        logInfo("  - Found \(result.duplicateTags.count) groups of duplicate tags")
        
        return result
    }
    
    /// Result of duplicate analysis (read-only)
    struct DuplicateAnalysisResult {
        var duplicateWords: [String: [CDWord]] = [:]
        var duplicateMeanings: [String: [CDMeaning]] = [:]
        var duplicateTags: [String: [CDTag]] = [:]
        
        var totalDuplicateWords: Int {
            return duplicateWords.values.reduce(0) { $0 + $1.count }
        }
        
        var totalDuplicateMeanings: Int {
            return duplicateMeanings.values.reduce(0) { $0 + $1.count }
        }
        
        var totalDuplicateTags: Int {
            return duplicateTags.values.reduce(0) { $0 + $1.count }
        }
        
        var hasDuplicates: Bool {
            return !duplicateWords.isEmpty || !duplicateMeanings.isEmpty || !duplicateTags.isEmpty
        }
    }
}
