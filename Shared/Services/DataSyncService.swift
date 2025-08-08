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

    static let shared = DataSyncService()

    private let db = Firestore.firestore()
    private let coreDataService = CoreDataService.shared
    private var cancellables = Set<AnyCancellable>()
    private var privateDictionaryListener: ListenerRegistration?

    let realTimeUpdateReceived = PassthroughSubject<Void, Never>()

    private init() {
        print("🔧 [DataSyncService] Initializing DataSyncService...")
        setupNetworkMonitoring()
    }

    // MARK: - Private Dictionary Sync

    func syncPrivateDictionaryToFirestore(userId: String) async throws {
        print("🔄 [DataSyncService] syncPrivateDictionaryToFirestore called with userId: \(userId)")

        guard !userId.isEmpty else {
            print("❌ [DataSyncService] Invalid userId provided")
            throw DataSyncError.invalidUserId
        }

        // Only sync unsynced words (new words or words marked as unsynced)
        let fetchRequest = CDWord.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "isSynced == false")

        let unsyncedWords = try coreDataService.context.fetch(fetchRequest)
        print("🔄 [DataSyncService] Found \(unsyncedWords.count) unsynced words in Core Data")
        
        guard !unsyncedWords.isEmpty else {
            print("✅ [DataSyncService] No unsynced words found, sync complete")
            return
        }

        let batch = db.batch()
        let totalWords = unsyncedWords.count
        var processedWords = 0

        print("🔄 [DataSyncService] Starting batch write to Firestore...")

        for entity in unsyncedWords {
            guard let word = Word(from: entity) else { 
                print("⚠️ [DataSyncService] Failed to convert entity to Word, skipping...")
                continue 
            }
            
            print("🔄 [DataSyncService] Processing word: '\(word.wordItself)' (ID: \(word.id))")
            
            let docRef = db
                .collection("users")
                .document(userId)
                .collection("words")
                .document(word.id)

            let firestoreData = word.toFirestoreDictionary()
            print("🔄 [DataSyncService] Word data for Firestore: \(firestoreData)")
            
            batch.setData(firestoreData, forDocument: docRef)

            processedWords += 1
            print("🔄 [DataSyncService] Processed \(processedWords)/\(totalWords) words")
        }

        print("🔄 [DataSyncService] Committing batch to Firestore...")
        try await batch.commit()

        print("✅ [DataSyncService] Batch commit successful, updating Core Data...")
        await self.coreDataService.context.perform {
            unsyncedWords.forEach { 
                $0.isSynced = true
                print("🔄 [DataSyncService] Marking word '\($0.wordItself ?? "unknown")' as synced")
            }
            
            do {
                try self.coreDataService.context.save()
                print("✅ [DataSyncService] Core Data saved successfully")
            } catch {
                print("❌ [DataSyncService] Failed to save Core Data: \(error.localizedDescription)")
            }
            
            print("✅ [DataSyncService] Private dictionary sync to Firestore completed successfully!")
        }
    }

    func syncFirestoreToCoreData(userId: String) async throws {
        print("🔍 [DataSyncService] syncFirestoreToCoreData called with userId: \(userId)")

        guard !userId.isEmpty else {
            print("❌ [DataSyncService] Invalid userId for sync from Firestore")
            throw DataSyncError.invalidUserId
        }

        let firestorePath = "users/\(userId)/privateDictionary/words/words"
        print("📡 [DataSyncService] Fetching words from Firestore path: \(firestorePath)")
        
        let snapshot = try await db.collection("users").document(userId).collection("words").getDocuments()
        print("📡 [DataSyncService] Firestore query completed")

        print("📄 [DataSyncService] Found \(snapshot.documents.count) documents in Firestore")

        await self.coreDataService.context.perform {
            var processedWords = 0
            let totalWords = snapshot.documents.count
            var newWordsCount = 0
            var updatedWordsCount = 0

            print("🔄 [DataSyncService] Processing \(totalWords) words in Core Data context...")

            for doc in snapshot.documents {
                print("🔄 [DataSyncService] Processing document: \(doc.documentID)")
                print("🔄 [DataSyncService] Document data: \(doc.data())")
                
                guard let word = Word.fromFirestoreDictionary(doc.data(), id: doc.documentID) else { 
                    print("⚠️ [DataSyncService] Failed to convert document to Word, skipping...")
                    continue 
                }
                
                print("🔄 [DataSyncService] Converted to Word: '\(word.wordItself)' (ID: \(word.id))")
                
                let fetchRequest = CDWord.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "id == %@", word.id)

                if let existing = try? self.coreDataService.context.fetch(fetchRequest).first {
                    print("🔄 [DataSyncService] Found existing word in Core Data: '\(existing.wordItself ?? "unknown")'")
                    self.mergeWord(existing: existing, remote: word)
                    updatedWordsCount += 1
                } else {
                    print("🔄 [DataSyncService] Creating new word in Core Data: '\(word.wordItself)'")
                    let entity = word.toCoreDataEntity()
                    entity.ownerId = userId  // Set owner for private words
                    self.syncTags(word: word, entity: entity)
                    newWordsCount += 1
                }

                processedWords += 1
                print("🔄 [DataSyncService] Processed \(processedWords)/\(totalWords) words")
            }

            print("🔄 [DataSyncService] Saving Core Data context...")
            do {
                try self.coreDataService.context.save()
                print("✅ [DataSyncService] Core Data saved successfully")
                print("📊 [DataSyncService] Sync summary: \(newWordsCount) new words, \(updatedWordsCount) updated words")
            } catch {
                print("❌ [DataSyncService] Failed to save Core Data: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Real-time Updates for Private Dictionary

    func startPrivateDictionaryListener(userId: String) {
        print("🔊 [DataSyncService] Starting real-time listener for private dictionary, userId: \(userId)")
        
        // Remove existing listener if any
        stopPrivateDictionaryListener()
        
        let firestorePath = "users/\(userId)/privateDictionary/words/words"
        print("📡 [DataSyncService] Setting up listener for path: \(firestorePath)")
        
        privateDictionaryListener = db.collection("users").document(userId)
            .collection("words")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { 
                    print("⚠️ [DataSyncService] Self is nil in private dictionary listener")
                    return 
                }
                
                if let error = error {
                    print("❌ [DataSyncService] Private dictionary listener error: \(error.localizedDescription)")
                    return
                }
                
                print("🔊 [DataSyncService] Private dictionary real-time update received")
                print("🔊 [DataSyncService] Snapshot metadata: \(snapshot?.metadata.description ?? "nil")")
                print("🔊 [DataSyncService] Snapshot has pending writes: \(snapshot?.metadata.hasPendingWrites ?? false)")
                
                guard let documents = snapshot?.documents else {
                    print("📄 [DataSyncService] No documents in private dictionary update")
                    return
                }
                
                print("📄 [DataSyncService] Received \(documents.count) documents in real-time update")
                
                self.coreDataService.context.perform { [weak self] in
                    var processedWords = 0
                    let totalWords = documents.count
                    
                    // Get all current document IDs from the snapshot
                    let currentDocumentIds = Set(documents.map { $0.documentID })
                    
                    // Check for deleted documents
                    let fetchRequest = CDWord.fetchRequest()
                                         let allLocalWords = ((try? self?.coreDataService.context.fetch(fetchRequest)) ?? [])
                         .filter { $0.sharedDictionaryId?.isEmpty ?? true }

                    for localWord in allLocalWords {
                        if let wordId = localWord.id?.uuidString, !currentDocumentIds.contains(wordId) {
                            print("🗑️ [DataSyncService] Word deleted from Firestore, removing from local storage: '\(localWord.wordItself ?? "unknown")' (ID: \(wordId))")
                            self?.coreDataService.context.delete(localWord)
                            try? self?.coreDataService.context.save()
                        }
                    }
                    
                    for doc in documents {
                        print("🔄 [DataSyncService] Processing real-time document: \(doc.documentID)")
                        print("🔄 [DataSyncService] Document data: \(doc.data())")
                        
                        guard let word = Word.fromFirestoreDictionary(doc.data(), id: doc.documentID) else { 
                            print("⚠️ [DataSyncService] Failed to convert real-time document to Word")
                            continue 
                        }
                        
                        let fetchRequest = CDWord.fetchRequest()
                        fetchRequest.predicate = NSPredicate(format: "id == %@", word.id)

                        if let existing = try? self?.coreDataService.context.fetch(fetchRequest).first {
                            print("🔄 [DataSyncService] Updating existing word in real-time: '\(existing.wordItself ?? "unknown")'")
                            self?.mergeWord(existing: existing, remote: word)
                        } else {
                            print("🔄 [DataSyncService] Creating new word in real-time: '\(word.wordItself)'")
                            let entity = word.toCoreDataEntity()
                            entity.ownerId = userId  // Set owner for private words
                            self?.syncTags(word: word, entity: entity)
                        }
                        
                        processedWords += 1
                    }
                    
                    print("🔄 [DataSyncService] Saving real-time updates to Core Data...")
                    do {
                        try self?.coreDataService.context.save()
                        print("✅ [DataSyncService] Real-time updates saved to Core Data")
                        
                        // Notify UI that real-time update was received
                        DispatchQueue.main.async { [weak self] in
                            self?.realTimeUpdateReceived.send()
                            print("🔄 [DataSyncService] Notified UI of real-time update")
                        }
                    } catch {
                        print("❌ [DataSyncService] Failed to save real-time updates: \(error.localizedDescription)")
                    }
                }
            }
    }

    func stopPrivateDictionaryListener() {
        print("🔊 [DataSyncService] Stopping private dictionary listener")
        privateDictionaryListener?.remove()
        privateDictionaryListener = nil
    }

    // MARK: - Individual Word Sync

    func syncWordToFirestore(word: CDWord, userId: String) async throws {
        print("🔄 [DataSyncService] Syncing individual word to Firestore: '\(word.wordItself ?? "unknown")'")
        
        guard let wordModel = Word(from: word) else {
            print("❌ [DataSyncService] Failed to convert word to Word model")
            throw DataSyncError.syncFailed
        }
        
        let docRef = db.collection("users").document(userId)
            .collection("words").document(wordModel.id)
        
        try await docRef.setData(wordModel.toFirestoreDictionary())

        print("✅ [DataSyncService] Word synced to Firestore successfully")
                
        // Mark as synced in Core Data
        await coreDataService.context.perform {
            word.isSynced = true
            try? self.coreDataService.context.save()
            print("✅ [DataSyncService] Word marked as synced in Core Data")
        }
    }

    func deleteWordFromFirestore(wordId: String, userId: String) async throws {
        print("🔄 [DataSyncService] Deleting word from Firestore: '\(wordId)'")
        
        let docRef = db.collection("users").document(userId)
            .collection("words").document(wordId)
        
        try await docRef.delete()

        print("✅ [DataSyncService] Word deleted from Firestore successfully")
    }

    // MARK: - Test Real-time Functionality
    /*
    func testRealTimeFunctionality(userId: String) {
        print("🧪 [DataSyncService] Testing real-time functionality for userId: \(userId)")
        
        // First, start the listener
        startPrivateDictionaryListener(userId: userId)
        
        // Then, add a test word to Firestore to trigger the listener
        let testWord = Word(
            id: UUID().uuidString,
            wordItself: "test_word_\(Date().timeIntervalSince1970)",
            definition: "A test word for real-time functionality",
            partOfSpeech: "noun",
            phonetic: "test",
            examples: ["This is a test example"],
            tags: ["test"],
            difficultyLevel: 1,
            languageCode: "en",
            isFavorite: false,
            timestamp: Date(),
            isSynced: true
        )
        
        print("🧪 [DataSyncService] Adding test word to Firestore: '\(testWord.wordItself)'")
        
        let docRef = db.collection("users").document(userId)
            .collection("words").document(testWord.id)
        
        docRef.setData(testWord.toFirestoreDictionary()) { error in
            if let error = error {
                print("❌ [DataSyncService] Failed to add test word: \(error.localizedDescription)")
            } else {
                print("✅ [DataSyncService] Test word added successfully")
                
                // Remove the test word after a delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    print("🧪 [DataSyncService] Removing test word from Firestore")
                    docRef.delete { error in
                        if let error = error {
                            print("❌ [DataSyncService] Failed to remove test word: \(error.localizedDescription)")
                        } else {
                            print("✅ [DataSyncService] Test word removed successfully")
                        }
                    }
                }
            }
        }
    }
    */

    // MARK: - Shared Dictionary Sync

    func syncSharedDictionaryWords(dictionaryId: String) {
        print("🔊 [DataSyncService] Starting real-time listener for shared dictionary: \(dictionaryId)")
        
        db.collection("dictionaries").document(dictionaryId).collection("words")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { 
                    print("⚠️ [DataSyncService] Self is nil in shared dictionary listener")
                    return 
                }
                
                if let error = error {
                    print("❌ [DataSyncService] Shared dictionary listener error: \(error.localizedDescription)")
                    return
                }
                
                print("🔊 [DataSyncService] Shared dictionary real-time update received")
                
                guard let documents = snapshot?.documents else {
                    print("📄 [DataSyncService] No documents in shared dictionary update")
                    return
                }

                print("📄 [DataSyncService] Received \(documents.count) documents in shared dictionary update")

                let context = coreDataService.context
                let words = documents.compactMap { doc -> Word? in
                    let word = Word.fromFirestoreDictionary(doc.data(), id: doc.documentID)
                    if word == nil {
                        print("⚠️ [DataSyncService] Failed to convert shared dictionary document to Word: \(doc.documentID)")
                    }
                    return word
                }

                print("🔄 [DataSyncService] Processing \(words.count) words from shared dictionary")

                context.perform {
                    // Get all current document IDs from the snapshot
                    let currentDocumentIds = Set(documents.map { $0.documentID })
                    
                    // Check for deleted documents in shared dictionary
                    let fetchRequest = CDWord.fetchRequest()
                                         fetchRequest.predicate = NSPredicate(format: "sharedDictionaryId == %@", dictionaryId)
                    let allLocalSharedWords = (try? context.fetch(fetchRequest)) ?? []
                    print("DEBUG50 2 [DataSyncService] Found \(allLocalSharedWords.count) shared words in local storage")
                    for localWord in allLocalSharedWords {
                        if let wordId = localWord.id?.uuidString, !currentDocumentIds.contains(wordId) {
                            print("🗑️ [DataSyncService] Word deleted from shared dictionary, removing from local storage: '\(localWord.wordItself ?? "unknown")' (ID: \(wordId))")
                            context.delete(localWord)
                            try? context.save()
                        }
                    }
                    
                    var newWordsCount = 0
                    var updatedWordsCount = 0
                    
                    for word in words {
                        print("🔄 [DataSyncService] Processing shared word: '\(word.wordItself)' (ID: \(word.id))")
                        
                        let fetchRequest = CDWord.fetchRequest()
                        fetchRequest.predicate = NSPredicate(format: "id == %@", word.id)

                        if let existing = try? context.fetch(fetchRequest).first {
                            print("🔄 [DataSyncService] Found existing shared word in Core Data: '\(existing.wordItself ?? "unknown")'")
                            if word.updatedAt >= existing.updatedAt ?? Date.distantPast {
                                print("🔄 [DataSyncService] Updating existing shared word with newer or equal data")
                                existing.wordItself = word.wordItself
                                existing.definition = word.definition
                                existing.partOfSpeech = word.partOfSpeech
                                existing.phonetic = word.phonetic
                                try? existing.updateExamples(word.examples)
                                existing.difficultyLevel = Int32(word.difficultyLevel)
                                existing.languageCode = word.languageCode
                                existing.isFavorite = word.isFavorite
                                existing.timestamp = word.timestamp
                                existing.updatedAt = word.updatedAt
                                existing.isSynced = true
                                existing.sharedDictionaryId = dictionaryId
                                self.syncTags(word: word, entity: existing)
                                updatedWordsCount += 1
                            } else {
                                print("🔄 [DataSyncService] Existing shared word is newer, skipping update")
                            }
                        } else {
                            print("🔄 [DataSyncService] Creating new shared word in Core Data: '\(word.wordItself)'")
                            let entity = word.toCoreDataEntity()
                            entity.sharedDictionaryId = dictionaryId
                            self.syncTags(word: word, entity: entity)
                            newWordsCount += 1
                        }
                    }

                    print("🔄 [DataSyncService] Saving shared dictionary updates to Core Data...")
                    do {
                        try context.save()
                        print("✅ [DataSyncService] Shared dictionary updates saved to Core Data")
                        print("📊 [DataSyncService] Shared dictionary sync summary: \(newWordsCount) new words, \(updatedWordsCount) updated words")
                        
                        // Update the WordsProvider
                        DispatchQueue.main.async {
                            WordsProvider.shared.updateSharedWords(for: dictionaryId)
                            self.realTimeUpdateReceived.send()
                            print("🔄 [DataSyncService] Notified UI of shared dictionary update")
                        }
                    } catch {
                        print("❌ [DataSyncService] Failed to save shared dictionary updates: \(error.localizedDescription)")
                    }
                }
            }
    }

    // MARK: - Tag Syncing

    private func syncTags(word: Word, entity: CDWord) {
        print("🏷️ [DataSyncService] Syncing tags for word: '\(word.wordItself)'")
        print("🏷️ [DataSyncService] Word tags: \(word.tags)")
        
        let fetchRequest = CDTag.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "name IN %@", word.tags)
        let existingTags = (try? coreDataService.context.fetch(fetchRequest)) ?? []
        let existingTagNames = existingTags.map { $0.name ?? "" }
        let newTags = word.tags.filter { !existingTagNames.contains($0) }

        print("🏷️ [DataSyncService] Found \(existingTags.count) existing tags, \(newTags.count) new tags to create")

        for tagName in newTags {
            print("🏷️ [DataSyncService] Creating new tag: '\(tagName)'")
            let tag = CDTag(context: coreDataService.context)
            tag.name = tagName
            tag.id = UUID()
            tag.timestamp = Date()
            entity.addToTags(tag)
        }

        for existingTag in existingTags {
            if word.tags.contains(existingTag.name ?? "") {
                print("🏷️ [DataSyncService] Adding existing tag to word: '\(existingTag.name ?? "unknown")'")
                entity.addToTags(existingTag)
            }
        }
    }

    // MARK: - Advanced Conflict Resolution

    func mergeWord(existing: CDWord, remote: Word) {
        print("🔄 [DataSyncService] Merging word: '\(existing.wordItself ?? "unknown")' with remote data")
        print("🔄 [DataSyncService] Existing updatedAt: \(existing.updatedAt?.description ?? "nil")")
        print("🔄 [DataSyncService] Remote updatedAt: \(remote.updatedAt)")
        
        // Merge if remote is newer or if timestamps are equal (for real-time updates)
        let shouldMerge = remote.updatedAt >= existing.updatedAt ?? Date.distantPast
        guard shouldMerge else { 
            print("🔄 [DataSyncService] Remote data is older, skipping merge")
            return 
        }
        
        print("🔄 [DataSyncService] Proceeding with merge (remote is newer or equal)")

        print("🔄 [DataSyncService] Remote data is newer, merging fields...")

        // Field-level merging to preserve changes from multiple users
        if remote.wordItself != existing.wordItself {
            print("🔄 [DataSyncService] Updating wordItself: '\(existing.wordItself ?? "nil")' -> '\(remote.wordItself)'")
            existing.wordItself = remote.wordItself
        }

        if remote.definition != existing.definition {
            print("🔄 [DataSyncService] Updating definition")
            existing.definition = remote.definition
        }

        if remote.partOfSpeech != existing.partOfSpeech {
            print("🔄 [DataSyncService] Updating partOfSpeech: '\(existing.partOfSpeech ?? "nil")' -> '\(remote.definition)'")
            existing.partOfSpeech = remote.partOfSpeech
        }

        if remote.phonetic != existing.phonetic {
            print("🔄 [DataSyncService] Updating phonetic")
            existing.phonetic = remote.phonetic
        }

        if remote.languageCode != existing.languageCode {
            print("🔄 [DataSyncService] Updating languageCode: '\(existing.languageCode ?? "nil")' -> '\(remote.languageCode)'")
            existing.languageCode = remote.languageCode
        }

        if remote.isFavorite != existing.isFavorite {
            print("🔄 [DataSyncService] Updating isFavorite: \(existing.isFavorite) -> \(remote.isFavorite)")
            existing.isFavorite = remote.isFavorite
        }

        // Merge arrays (examples and tags)
        mergeExamples(existing: existing, remote: remote)
        mergeTags(existing: existing, remote: remote)

        // Update difficulty level if changed
        if Int(remote.difficultyLevel) != Int(existing.difficultyLevel) {
            print("🔄 [DataSyncService] Updating difficultyLevel: \(existing.difficultyLevel) -> \(remote.difficultyLevel)")
            existing.difficultyLevel = Int32(remote.difficultyLevel)
        }

        // Update updatedAt to the latest
        existing.updatedAt = max(existing.updatedAt ?? Date.distantPast, remote.updatedAt)
        existing.isSynced = true
        
        print("✅ [DataSyncService] Word merge completed successfully")
    }

    private func mergeExamples(existing: CDWord, remote: Word) {
        let existingExamples = existing.examplesDecoded
        let remoteExamples = remote.examples

        print("🔄 [DataSyncService] Merging examples for word: '\(existing.wordItself ?? "unknown")'")
        print("🔄 [DataSyncService] Existing examples count: \(existingExamples.count)")
        print("🔄 [DataSyncService] Remote examples count: \(remoteExamples.count)")

        // Merge examples, removing duplicates while preserving order
        var mergedExamples = existingExamples
        for example in remoteExamples {
            if !mergedExamples.contains(example) {
                print("🔄 [DataSyncService] Adding new example: '\(example)'")
                mergedExamples.append(example)
            }
        }

        // Only update if there are changes
        if mergedExamples != existingExamples {
            print("🔄 [DataSyncService] Updating examples (merged count: \(mergedExamples.count))")
            try? existing.updateExamples(mergedExamples)
        } else {
            print("🔄 [DataSyncService] No changes to examples")
        }
    }

    private func mergeTags(existing: CDWord, remote: Word) {
        let existingTagNames = existing.tagsArray.map { $0.name ?? "" }
        let remoteTagNames = remote.tags

        print("🔄 [DataSyncService] Merging tags for word: '\(existing.wordItself ?? "unknown")'")
        print("🔄 [DataSyncService] Existing tags: \(existingTagNames)")
        print("🔄 [DataSyncService] Remote tags: \(remoteTagNames)")

        // Find new tags to add
        let newTagNames = remoteTagNames.filter { !existingTagNames.contains($0) }
        print("🔄 [DataSyncService] New tags to add: \(newTagNames)")

        // Add new tags
        for tagName in newTagNames {
            print("🔄 [DataSyncService] Creating new tag: '\(tagName)'")
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

        print("🔄 [DataSyncService] Tags to remove: \(tagsToRemove.map { $0.name ?? "unknown" })")

        for tag in tagsToRemove {
            print("🔄 [DataSyncService] Removing tag: '\(tag.name ?? "unknown")'")
            existing.removeFromTags(tag)
            coreDataService.context.delete(tag)
            try? coreDataService.context.save()
        }
    }

    // MARK: - Network Monitoring

    private func setupNetworkMonitoring() {
        print("🔧 [DataSyncService] Setting up network monitoring...")
        
        // Monitor network connectivity for automatic sync
        NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave)
            .sink { [weak self] _ in
                guard let self = self,
                      let userId = AuthenticationService.shared.userId else { 
                    print("⚠️ [DataSyncService] Cannot sync: self is nil or userId is nil")
                    return 
                }

                print("🔄 [DataSyncService] Core Data context saved, triggering sync to Firestore...")
                // Sync to Firestore when Core Data changes
                Task {
                    do {
                        try await self.syncPrivateDictionaryToFirestore(userId: userId)
                        print("✅ [DataSyncService] Auto-sync to Firestore completed successfully")
                    } catch {
                        print("❌ [DataSyncService] Auto-sync to Firestore failed: \(error.localizedDescription)")
                    }
                }
            }
            .store(in: &cancellables)

        // Monitor iCloud sync completion
        NotificationCenter.default.publisher(for: .NSPersistentStoreDidImportUbiquitousContentChanges)
            .sink { [weak self] _ in
                guard let self = self,
                      let userId = AuthenticationService.shared.userId else { 
                    print("⚠️ [DataSyncService] Cannot sync after iCloud changes: self is nil or userId is nil")
                    return 
                }

                print("🔄 [DataSyncService] iCloud content changes detected, waiting before sync...")
                // Wait a bit for iCloud sync to complete, then sync to Firestore
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    print("🔄 [DataSyncService] Triggering sync after iCloud changes...")
                    Task {
                        do {
                            try await self.syncPrivateDictionaryToFirestore(userId: userId)
                            print("✅ [DataSyncService] Post-iCloud sync to Firestore completed successfully")
                        } catch {
                            print("❌ [DataSyncService] Post-iCloud sync to Firestore failed: \(error.localizedDescription)")
                        }
                    }
                }
            }
            .store(in: &cancellables)
            
        print("✅ [DataSyncService] Network monitoring setup completed")
    }

    // MARK: - Migration Support

    func convertPrivateToSharedDictionary(userId: String, name: String) async throws {
        print("🔄 [DataSyncService] Converting private to shared dictionary...")
        print("🔄 [DataSyncService] UserId: \(userId), Name: \(name)")
        
        let fetchRequest = CDWord.fetchRequest()

        do {
            let words = try coreDataService.context.fetch(fetchRequest).compactMap { Word(from: $0) }
            print("🔄 [DataSyncService] Found \(words.count) words to convert")
            
            let dictRef = db.collection("dictionaries").document()
            let batch = db.batch()

            batch.setData([
                "name": name,
                "owner": userId,
                "collaborators": [userId: CollaboratorRole.owner.rawValue],
                "createdAt": Timestamp(date: Date())
            ], forDocument: dictRef)

            for word in words {
                let wordRef = dictRef.collection("words").document(word.id)
                batch.setData(word.toFirestoreDictionary(), forDocument: wordRef)
            }

            print("🔄 [DataSyncService] Committing batch for dictionary conversion...")
            try await batch.commit()

            print("✅ [DataSyncService] Dictionary conversion completed successfully")
        } catch {
            print("❌ [DataSyncService] Failed to fetch words for conversion: \(error.localizedDescription)")
            throw error
        }
    }
}

// MARK: - Errors

enum DataSyncError: LocalizedError {
    case invalidUserId
    case networkError
    case syncFailed

    var errorDescription: String? {
        switch self {
        case .invalidUserId:
            return "Invalid user ID"
        case .networkError:
            return "Network error occurred"
        case .syncFailed:
            return "Sync failed"
        }
    }
}

