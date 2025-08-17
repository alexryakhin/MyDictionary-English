//
//  DataSyncService.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import Foundation
import FirebaseFirestore
import Combine

final class DataSyncService: ObservableObject {

    private enum Constants {
        static let maxBatchSize = 500 // Firestore batch limit
        static let retryAttempts = 3
        static let retryDelay: TimeInterval = 2.0
    }

    static let shared = DataSyncService()

    private let db = Firestore.firestore()
    private let coreDataService = CoreDataService.shared
    private let authenticationService = AuthenticationService.shared

    // Sync state tracking
    @Published var isUploading = false
    @Published var isRestoring = false

    private init() {}

    // MARK: - Manual Sync Methods

    func uploadBackupToGoogle(userEmail: String) async throws {
        guard !userEmail.isEmpty else { throw DataSyncError.invalidUserEmail }

        // Set uploading flag
        await MainActor.run {
            isUploading = true
        }
        defer {
            Task { @MainActor in isUploading = false }
        }

        // Get all current local words
        let fetchRequest = CDWord.fetchRequest()
        let allLocalWords = try coreDataService.context.fetch(fetchRequest)

        // Get all current Firebase words to identify what needs to be deleted
        let snapshot = try await db
            .collection("users")
            .document(userEmail)
            .collection("words")
            .getDocuments()

        let firebaseWordIds = Set(snapshot.documents.map { $0.documentID })
        let localWordIds = Set(allLocalWords.compactMap { $0.id?.uuidString })

        // Find words that exist in Firebase but not locally (need to be deleted)
        let wordsToDelete = firebaseWordIds.subtracting(localWordIds)

        // OPTIMIZATION: Use batch operations for deletions
        if !wordsToDelete.isEmpty {
            let deletionBatches = Array(wordsToDelete).chunked(into: Constants.maxBatchSize)

            for deletionBatch in deletionBatches {
                let batch = db.batch()

                for wordId in deletionBatch {
                    let docRef = db
                        .collection("users")
                        .document(userEmail)
                        .collection("words")
                        .document(wordId)

                    batch.deleteDocument(docRef)
                }

                try await batch.commit()
            }
        }

        // Upload all current local words using optimized batch upload
        try await uploadAllWordsInBatches(userEmail: userEmail, words: allLocalWords)
    }

    func downloadBackupFromGoogle(userEmail: String) async throws {
        guard !userEmail.isEmpty else {
            throw DataSyncError.invalidUserEmail
        }

        await MainActor.run { isRestoring = true }
        defer {
            Task { @MainActor in isRestoring = false }
        }

        // Download all words from Firestore
        try await syncFirestoreToCoreData(userEmail: userEmail)
    }

    // MARK: - Optimized Batch Upload

    private func uploadAllWordsInBatches(userEmail: String, words: [CDWord]) async throws {
        // Process in batches to avoid Firestore limits
        let batches = words.chunked(into: Constants.maxBatchSize)

        for (batchIndex, batch) in batches.enumerated() {
            let firestoreBatch = db.batch()
            var processedWords = 0

            for entity in batch {
                guard let word = Word(from: entity) else {
                    continue
                }

                let docRef = db
                    .collection("users")
                    .document(userEmail)
                    .collection("words")
                    .document(word.id)

                let firestoreData = word.toFirestoreDictionary()
                firestoreBatch.setData(firestoreData, forDocument: docRef)

                processedWords += 1
            }

            // Commit batch with retry logic
            try await commitBatchWithRetry(firestoreBatch, batchIndex: batchIndex)

            // Mark words as synced in Core Data
            try await coreDataService.context.perform {
                batch.forEach {
                    $0.isSynced = true
                }

                try self.coreDataService.context.save()
            }
        }
    }

    // MARK: - Optimized Batch Download

    private func downloadAllDocumentsInBatches(userEmail: String) async throws -> [QueryDocumentSnapshot] {
        var allDocuments: [QueryDocumentSnapshot] = []
        var lastDocument: QueryDocumentSnapshot?
        let batchSize = 1000 // Firestore query limit per batch

        repeat {
            var query = db.collection("users").document(userEmail).collection("words").limit(to: batchSize)

            if let lastDoc = lastDocument {
                query = query.start(afterDocument: lastDoc)
            }

            let snapshot = try await query.getDocuments()
            let documents = snapshot.documents

            allDocuments.append(contentsOf: documents)

            lastDocument = documents.last

            // Continue if we got a full batch (might be more data)
        } while lastDocument != nil && allDocuments.count % batchSize == 0

        return allDocuments
    }

    private func processDownloadedDocumentsInBatches(documents: [QueryDocumentSnapshot]) async throws {
        // Process in batches for Core Data efficiency
        let batches = documents.chunked(into: 100) // Smaller batches for Core Data processing

        var totalNewWords = 0
        var totalUpdatedWords = 0

        for batch in batches {
            try await self.coreDataService.context.perform {
                var batchNewWords = 0
                var batchUpdatedWords = 0

                for doc in batch {
                    guard let word = Word.fromFirestoreDictionary(doc.data(), id: doc.documentID) else {
                        continue
                    }

                    let fetchRequest = CDWord.fetchRequest()
                    fetchRequest.predicate = NSPredicate(format: "id == %@", word.id)

                    if let existing = try? self.coreDataService.context.fetch(fetchRequest).first {
                        self.mergeWord(existing: existing, remote: word)
                        batchUpdatedWords += 1
                    } else {
                        let entity = word.toCoreDataEntity()
                        self.syncTags(word: word, entity: entity)
                        batchNewWords += 1
                    }
                }

                // Save this batch to Core Data
                try self.coreDataService.context.save()

                totalNewWords += batchNewWords
                totalUpdatedWords += batchUpdatedWords
            }
        }
    }

    // MARK: - Private Dictionary Sync

    private func commitBatchWithRetry(_ batch: WriteBatch, batchIndex: Int) async throws {
        var lastError: Error?

        for attempt in 1...Constants.retryAttempts {
            do {
                try await batch.commit()
                return
            } catch {
                lastError = error

                if attempt < Constants.retryAttempts {
                    try await Task.sleep(nanoseconds: UInt64(Constants.retryDelay * 1_000_000_000))
                } else if let lastError {
                    throw lastError
                }
            }
        }

        throw DataSyncError.syncFailed
    }

    func syncFirestoreToCoreData(userEmail: String) async throws {
        guard userEmail.isNotEmpty else {
            throw DataSyncError.invalidUserEmail
        }

        // Use batched downloads for large datasets
        let allDocuments = try await downloadAllDocumentsInBatches(userEmail: userEmail)

        // Process downloaded documents in batches for Core Data efficiency
        try await processDownloadedDocumentsInBatches(documents: allDocuments)
    }

    // MARK: - Tag Syncing

    private func syncTags(word: Word, entity: CDWord) {
        let fetchRequest = CDTag.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "name IN %@", word.tags)
        let existingTags = (try? coreDataService.context.fetch(fetchRequest)) ?? []
        let existingTagNames = existingTags.map { $0.name ?? "" }
        let newTags = word.tags.filter { !existingTagNames.contains($0) }

        for tagName in newTags {
            let tag = CDTag(context: coreDataService.context)
            tag.name = tagName
            tag.id = UUID()
            tag.timestamp = Date()
            entity.addToTags(tag)
        }

        for existingTag in existingTags {
            if word.tags.contains(existingTag.name ?? "") {
                entity.addToTags(existingTag)
            }
        }
    }

    // MARK: - Advanced Conflict Resolution

    func mergeWord(existing: CDWord, remote: Word) {
        // Merge if remote is newer or if timestamps are equal (for real-time updates)
        let shouldMerge = remote.updatedAt >= existing.updatedAt ?? Date.distantPast
        guard shouldMerge else { return }

        // Field-level merging to preserve changes from multiple users
        if remote.wordItself != existing.wordItself {
            existing.wordItself = remote.wordItself
        }

        if remote.definition != existing.definition {
            existing.definition = remote.definition
        }

        if remote.partOfSpeech != existing.partOfSpeech {
            existing.partOfSpeech = remote.partOfSpeech
        }

        if remote.phonetic != existing.phonetic {
            existing.phonetic = remote.phonetic
        }

        if remote.languageCode != existing.languageCode {
            existing.languageCode = remote.languageCode
        }

        // Update preferences from remote for all words
        if remote.isFavorite != existing.isFavorite {
            existing.isFavorite = remote.isFavorite
        }

        // Update difficulty score if changed
        if Int(remote.difficultyScore) != Int(existing.difficultyScore) {
            existing.difficultyScore = Int32(remote.difficultyScore)
        }

        // Merge arrays (examples and tags)
        mergeExamples(existing: existing, remote: remote)
        mergeTags(existing: existing, remote: remote)

        // Update updatedAt to the latest
        existing.updatedAt = max(existing.updatedAt ?? Date.distantPast, remote.updatedAt)
        existing.isSynced = true
    }

    private func mergeExamples(existing: CDWord, remote: Word) {
        let existingExamples = existing.examplesDecoded
        let remoteExamples = remote.examples

        // Merge examples, removing duplicates while preserving order
        var mergedExamples = existingExamples
        for example in remoteExamples {
            if !mergedExamples.contains(example) {
                mergedExamples.append(example)
            }
        }

        // Only update if there are changes
        if mergedExamples != existingExamples {
            try? existing.updateExamples(mergedExamples)
        }
    }

    private func mergeTags(existing: CDWord, remote: Word) {
        let existingTagNames = existing.tagsArray.map { $0.name ?? "" }
        let remoteTagNames = remote.tags

        // Find new tags to add
        let newTagNames = remoteTagNames.filter { !existingTagNames.contains($0) }

        // Add new tags
        for tagName in newTagNames {
            let tag = CDTag(context: coreDataService.context)
            tag.name = tagName
            tag.id = UUID()
            tag.timestamp = Date()
            existing.addToTags(tag)
        }

        // Remove tags that are no longer in remote
        let tagsToRemove = existing.tagsArray.filter { tag in
            let tagName = tag.name ?? ""
            return !remoteTagNames.contains(tagName)
        }

        for tag in tagsToRemove {
            existing.removeFromTags(tag)
            coreDataService.context.delete(tag)
        }
    }
}

// MARK: - Errors

enum DataSyncError: Error, LocalizedError {
    case invalidUserEmail
    case networkError
    case syncFailed

    var errorDescription: String? {
        switch self {
        case .invalidUserEmail:
            return Loc.Errors.invalidUserEmail.localized
        case .networkError:
            return Loc.Errors.networkErrorOccurred.localized
        case .syncFailed:
            return Loc.Errors.syncFailed.localized
        }
    }
}

