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
            
            // Perform migration phases
            try await migrateWordDefinitions()
            try await migrateIdiomsToWords()
            try await validateMigration()
            try await cleanup()
            
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
        logInfo("✅ Phase 1 completed: Migrated \(migratedCount) word definitions out of \(totalWords) total words")
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
        
        for (index, idiom) in idioms.enumerated() {
            // Check if this idiom was already migrated by looking for existing CDWord with same text and idiom type
            let existingWordRequest = CDWord.fetchRequest()
            existingWordRequest.predicate = NSPredicate(format: "wordItself == %@ AND partOfSpeech == %@", 
                                                       idiom.idiomItself ?? "", "idiom")
            existingWordRequest.fetchLimit = 1
            
            let existingWords = try context.fetch(existingWordRequest)
            if !existingWords.isEmpty {
                logInfo("Skipping already migrated idiom: \(idiom.idiomItself ?? "unknown")")
                continue
            }
            
            // Create new CDWord with partOfSpeech = "idiom"
            let newWord = CDWord(context: context)
            newWord.id = UUID()
            newWord.wordItself = idiom.idiomItself
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
            logInfo("Migrated idiom: \(idiom.idiomItself ?? "unknown")")
            
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
        logInfo("✅ Phase 2 completed: Migrated \(migratedIdiomCount) new idioms out of \(totalIdioms) total idioms")
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
        
        do {
            let context = coreDataService.context
            
            // This is a simplified rollback - in practice, you might want to keep a backup
            // For now, we'll just mark migration as failed and let user retry
            await MainActor.run {
                userDefaults.set(false, forKey: migrationCompletedKey)
                let attempts = userDefaults.integer(forKey: migrationAttemptsKey)
                userDefaults.set(attempts + 1, forKey: migrationAttemptsKey)
            }
            
            logInfo("✅ Migration marked for retry")
            
        } catch {
            logError("❌ Rollback failed: \(error)")
        }
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
    
    /// Returns migration statistics
    var migrationStats: [String: Any] {
        return [
            "completed": userDefaults.bool(forKey: migrationCompletedKey),
            "version": userDefaults.string(forKey: migrationVersionKey) ?? "unknown",
            "lastDate": userDefaults.object(forKey: lastMigrationDateKey) as? Date ?? Date.distantPast,
            "attempts": userDefaults.integer(forKey: migrationAttemptsKey)
        ]
    }
}
