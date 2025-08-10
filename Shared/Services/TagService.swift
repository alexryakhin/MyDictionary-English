//
//  TagService.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/9/25.
//

import Foundation
import CoreData
import Combine
import FirebaseFirestore

final class TagService: ObservableObject {

    static let shared = TagService()

    @Published var tags: [CDTag] = []

    private let coreDataService: CoreDataService = .shared
    private let db = Firestore.firestore()
    private var cancellables: Set<AnyCancellable> = []

    private init() {
        setupBindings()
    }
    
    // MARK: - Tag Management
    
    func getAllTags() {
        let request = CDTag.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        
        do {
            tags = try coreDataService.context.fetch(request)
        } catch {
            print("Error fetching tags: \(error)")
        }
    }
    
    func createTag(name: String, color: TagColor) throws {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw CoreError.internalError(.inputCannotBeEmpty)
        }
        
        // Check if tag with same name already exists
        let request = CDTag.fetchRequest()
        request.predicate = NSPredicate(format: "name == %@", name.trimmingCharacters(in: .whitespacesAndNewlines))
        
        do {
            let existingTags = try coreDataService.context.fetch(request)
            if !existingTags.isEmpty {
                throw CoreError.internalError(.tagAlreadyExists)
            }
        } catch {
            throw error
        }
        
        let newTag = CDTag(context: coreDataService.context)
        newTag.id = UUID()
        newTag.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        newTag.color = color.rawValue
        newTag.timestamp = Date()
        
        try coreDataService.saveContext()
    }
    
    func deleteTag(_ tag: CDTag) throws {
        let tagName = tag.name ?? ""
        print("🏷️ [TagService] Deleting tag: '\(tagName)'")
        
        // Get all words that have this tag
        let wordsWithTag = tag.wordsArray
        print("🏷️ [TagService] Found \(wordsWithTag.count) words with tag '\(tagName)'")
        
        // Remove tag from all words in Core Data
        for word in wordsWithTag {
            word.removeFromTags(tag)
        }
        
        // Delete the tag from Core Data
        coreDataService.context.delete(tag)
        try coreDataService.saveContext()
        
        // Sync the updated words to Firestore
        Task {
            await syncWordsToFirestoreAfterTagDeletion(words: wordsWithTag, deletedTagName: tagName)
        }
    }
    
    private func syncWordsToFirestoreAfterTagDeletion(words: [CDWord], deletedTagName: String) async {
        guard let userId = AuthenticationService.shared.userId else {
            print("❌ [TagService] No authenticated user found for Firestore sync")
            return
        }
        
        print("🔄 [TagService] Syncing \(words.count) words to Firestore after tag deletion")
        
        let batch = db.batch()
        
        for word in words {
            guard let wordModel = Word(from: word) else {
                print("⚠️ [TagService] Failed to convert word to model: \(word.wordItself ?? "unknown")")
                continue
            }
            
            let docRef = db
                .collection("users")
                .document(userId)
                .collection("words")
                .document(wordModel.id)
            
            let firestoreData = wordModel.toFirestoreDictionary()
            batch.setData(firestoreData, forDocument: docRef)
            
            print("🔄 [TagService] Updated word '\(wordModel.wordItself)' in Firestore batch")
        }
        
        do {
            try await batch.commit()
            print("✅ [TagService] Successfully synced \(words.count) words to Firestore after tag deletion")
        } catch {
            print("❌ [TagService] Failed to sync words to Firestore after tag deletion: \(error.localizedDescription)")
        }
    }
    
    func updateTag(_ tag: CDTag, name: String, color: TagColor) throws {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw CoreError.internalError(.inputCannotBeEmpty)
        }
        
        // Check if another tag with same name already exists
        let request = CDTag.fetchRequest()
        request.predicate = NSPredicate(format: "name == %@ AND id != %@", 
                                      name.trimmingCharacters(in: .whitespacesAndNewlines), 
                                      tag.id?.uuidString ?? "")
        
        do {
            let existingTags = try coreDataService.context.fetch(request)
            if !existingTags.isEmpty {
                throw CoreError.internalError(.tagAlreadyExists)
            }
        } catch {
            throw error
        }
        
        let oldName = tag.name ?? ""
        tag.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        tag.color = color.rawValue
        
        try coreDataService.saveContext()
        
        // If name changed, sync to Firestore
        if oldName != tag.name {
            let wordsWithTag = tag.wordsArray
            Task {
                await syncWordsToFirestoreAfterTagDeletion(words: wordsWithTag, deletedTagName: oldName)
            }
        }
    }
    
    // MARK: - Word-Tag Relationships
    
    func addTagToWord(_ tag: CDTag, word: CDWord) throws {
        guard !isWordTagged(word, with: tag) else {
            throw CoreError.internalError(.tagAlreadyAssigned)
        }
        
        // Check if word already has 5 tags
        if word.tagsArray.count >= 5 {
            throw CoreError.internalError(.maxTagsReached)
        }
        
        tag.addToWords(word)
        try coreDataService.saveContext()
        
        // Sync to Firestore
        Task {
            await syncWordToFirestore(word: word)
        }
    }
    
    func removeTagFromWord(_ tag: CDTag, word: CDWord) throws {
        guard isWordTagged(word, with: tag) else {
            throw CoreError.internalError(.tagNotAssigned)
        }
        
        tag.removeFromWords(word)
        try coreDataService.saveContext()
        
        // Sync to Firestore
        Task {
            await syncWordToFirestore(word: word)
        }
    }
    
    private func syncWordToFirestore(word: CDWord) async {
        guard let userId = AuthenticationService.shared.userId else {
            print("❌ [TagService] No authenticated user found for Firestore sync")
            return
        }
        
        guard let wordModel = Word(from: word) else {
            print("⚠️ [TagService] Failed to convert word to model: \(word.wordItself ?? "unknown")")
            return
        }
        
        do {
            let docRef = db
                .collection("users")
                .document(userId)
                .collection("words")
                .document(wordModel.id)
            
            try await docRef.setData(wordModel.toFirestoreDictionary())
            print("✅ [TagService] Successfully synced word '\(wordModel.wordItself)' to Firestore")
        } catch {
            print("❌ [TagService] Failed to sync word to Firestore: \(error.localizedDescription)")
        }
    }
    
    func getWordsForTag(_ tag: CDTag) -> [CDWord] {
        return tag.wordsArray
    }
    
    func getTagsForWord(_ word: CDWord) -> [CDTag] {
        return word.tagsArray
    }
    
    func isWordTagged(_ word: CDWord, with tag: CDTag) -> Bool {
        return word.tagsArray.contains { $0.id == tag.id }
    }

    private func setupBindings() {
        coreDataService.dataUpdatedPublisher
            .sink { [weak self] _ in
                self?.getAllTags()
            }
            .store(in: &cancellables)

        // Also listen to real-time updates from DataSyncService
        DataSyncService.shared.realTimeUpdateReceived
            .sink { [weak self] _ in
                self?.getAllTags()
            }
            .store(in: &cancellables)
    }
}
