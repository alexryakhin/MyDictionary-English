//
//  DictionaryService.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import Foundation
import FirebaseFirestore
import FirebaseFunctions
import Combine

final class DictionaryService: ObservableObject {

    static let shared = DictionaryService()

    private let coreDataService = CoreDataService.shared
    private let db = Firestore.firestore()
    private let functions = Functions.functions()
    private var cancellables = Set<AnyCancellable>()
    private var listeners: [String: ListenerRegistration] = [:]
    
    @Published var sharedDictionaries: [SharedDictionary] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    struct SharedDictionary: Identifiable, Codable {
        let id: String
        let name: String
        let owner: String
        let collaborators: [String: String]
        let createdAt: Date
        
        var userRole: String? {
            guard let userId = AuthenticationService.shared.userId else { return nil }
            return collaborators[userId]
        }
        
        var canEdit: Bool {
            guard let userId = AuthenticationService.shared.userId else { return false }
            return owner == userId || collaborators[userId] == "editor"
        }
        
        var canView: Bool {
            guard let userId = AuthenticationService.shared.userId else { return false }
            return owner == userId || collaborators[userId] != nil
        }
        
        var isOwner: Bool {
            guard let userId = AuthenticationService.shared.userId else { return false }
            return owner == userId
        }
    }
    
    private init() {
        setupSharedDictionariesListener()
    }
    
    // MARK: - Shared Dictionary Management
    
    func createSharedDictionary(userId: String, name: String, completion: @escaping (Result<String, Error>) -> Void) {
        print("🔍 [DictionaryService] createSharedDictionary called with userId: \(userId), name: \(name)")
        
        guard !userId.isEmpty, !name.isEmpty else {
            print("❌ [DictionaryService] Invalid input - userId: \(userId), name: \(name)")
            completion(.failure(DictionaryError.invalidInput))
            return
        }
        
        isLoading = true
        print("🔄 [DictionaryService] Setting isLoading = true")
        
        let data: [String: Any] = [
            "name": name,
            "owner": userId,
            "collaborators": [userId: "editor"],
            "createdAt": Timestamp(date: Date())
        ]
        
        print("📝 [DictionaryService] Creating dictionary with data: \(data)")
        let docRef = db
            .collection("dictionaries")
            .document()
        print("📄 [DictionaryService] Document reference: \(docRef.path)")
        
        docRef.setData(data) { [weak self] error in
            print("📤 [DictionaryService] setData completion called")
            
            DispatchQueue.main.async { [weak self] in
                self?.isLoading = false
                print("🔄 [DictionaryService] Setting isLoading = false")
            }
            
            if let error = error {
                print("❌ [DictionaryService] Error creating dictionary: \(error.localizedDescription)")
                completion(.failure(error))
            } else {
                print("✅ [DictionaryService] Dictionary created successfully with ID: \(docRef.documentID)")
                completion(.success(docRef.documentID))
            }
        }
    }
    
    func addCollaborator(dictionaryId: String, email: String, role: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard !dictionaryId.isEmpty, !email.isEmpty, ["editor", "viewer"].contains(role) else {
            completion(.failure(DictionaryError.invalidInput))
            return
        }
        
        isLoading = true
        
        functions.httpsCallable("addCollaborator").call([
            "dictionaryId": dictionaryId,
            "email": email,
            "role": role
        ]) { [weak self] result, error in
            DispatchQueue.main.async { [weak self] in
                self?.isLoading = false
            }
            
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    func removeCollaborator(dictionaryId: String, userId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard !dictionaryId.isEmpty, !userId.isEmpty else {
            completion(.failure(DictionaryError.invalidInput))
            return
        }
        
        isLoading = true
        
        functions.httpsCallable("removeCollaborator").call([
            "dictionaryId": dictionaryId,
            "userId": userId
        ]) { [weak self] result, error in
            DispatchQueue.main.async { [weak self] in
                self?.isLoading = false
            }
            
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    func updateCollaboratorRole(dictionaryId: String, userId: String, role: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard !dictionaryId.isEmpty, !userId.isEmpty, ["editor", "viewer"].contains(role) else {
            completion(.failure(DictionaryError.invalidInput))
            return
        }
        
        isLoading = true
        
        db
            .collection("dictionaries")
            .document(dictionaryId)
            .updateData([
                "collaborators.\(userId)": role
            ]) { [weak self] error in
                DispatchQueue.main.async { [weak self] in
                    self?.isLoading = false
                }

                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
    }
    
    func deleteSharedDictionary(dictionaryId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard !dictionaryId.isEmpty else {
            completion(.failure(DictionaryError.invalidInput))
            return
        }
        
        isLoading = true
        
        // Delete all words in the dictionary first
        db
            .collection("dictionaries")
            .document(dictionaryId)
            .collection("words")
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    DispatchQueue.main.async { [weak self] in
                        self?.isLoading = false
                    }
                    completion(.failure(error))
                    return
                }
                
                let batch = self.db.batch()
                
                // Delete all words
                snapshot?.documents.forEach { doc in
                    batch.deleteDocument(doc.reference)
                }
                
                // Delete the dictionary document
                batch.deleteDocument(self.db.collection("dictionaries").document(dictionaryId))
                
                batch.commit { error in
                    DispatchQueue.main.async { [weak self] in
                        self?.isLoading = false
                    }
                    
                    if let error = error {
                        completion(.failure(error))
                    } else {
                        completion(.success(()))
                    }
                }
            }
    }
    
    // MARK: - Word Management in Shared Dictionaries
    
    func addWordToSharedDictionary(dictionaryId: String, word: Word, completion: @escaping (Result<Void, Error>) -> Void) {
        print("🔍 [DictionaryService] addWordToSharedDictionary called with dictionaryId: \(dictionaryId), word: \(word.wordItself)")
        
        guard !dictionaryId.isEmpty else {
            print("❌ [DictionaryService] Invalid dictionaryId: \(dictionaryId)")
            completion(.failure(DictionaryError.invalidInput))
            return
        }
        
        let docRef = db
            .collection("dictionaries")
            .document(dictionaryId)
            .collection("words")
            .document(word.id)

        print("📄 [DictionaryService] Word document reference: \(docRef.path)")
        
        let wordData = word.toFirestoreDictionary()
        print("📝 [DictionaryService] Word data: \(wordData)")
        
        docRef.setData(wordData) { error in
            print("📤 [DictionaryService] setData completion called for word")
            
            if let error = error {
                print("❌ [DictionaryService] Error adding word: \(error.localizedDescription)")
                completion(.failure(error))
            } else {
                print("✅ [DictionaryService] Word added successfully to dictionary: \(dictionaryId)")
                completion(.success(()))
            }
        }
    }
    
    func updateWordInSharedDictionary(dictionaryId: String, word: Word, completion: @escaping (Result<Void, Error>) -> Void) {
        guard !dictionaryId.isEmpty else {
            completion(.failure(DictionaryError.invalidInput))
            return
        }
        
        let docRef = db
            .collection("dictionaries")
            .document(dictionaryId)
            .collection("words")
            .document(word.id)

        docRef.updateData(word.toFirestoreDictionary()) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    func deleteWordFromSharedDictionary(dictionaryId: String, wordId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard !dictionaryId.isEmpty, !wordId.isEmpty else {
            completion(.failure(DictionaryError.invalidInput))
            return
        }
        
        let docRef = db
            .collection("dictionaries")
            .document(dictionaryId)
            .collection("words")
            .document(wordId)

        docRef.delete { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
//    func updateWordInSharedDictionary(dictionaryId: String, word: Word, completion: @escaping (Result<Void, Error>) -> Void) {
//        guard !dictionaryId.isEmpty else {
//            completion(.failure(DictionaryError.invalidInput))
//            return
//        }
//        
//        var wordData = word.toFirestoreDictionary()
//        wordData["updatedAt"] = Timestamp(date: Date())
//        
//        let docRef = db.collection("dictionaries").document(dictionaryId).collection("words").document(word.id)
//        docRef.setData(wordData) { error in
//            if let error = error {
//                completion(.failure(error))
//            } else {
//                completion(.success(()))
//            }
//        }
//    }
    
    // MARK: - Real-time Listeners
    
    func setupSharedDictionariesListener() {
        print("🔍 [DictionaryService] setupSharedDictionariesListener called")
        
        guard let userId = AuthenticationService.shared.userId else { 
            print("❌ [DictionaryService] No userId found in AuthenticationService")
            return 
        }
        
        print("👤 [DictionaryService] User ID: \(userId)")
        print("📡 [DictionaryService] Setting up listener for dictionaries collection")
        
        // Query dictionaries where user is a collaborator
        let collaboratorQuery = db
            .collection("dictionaries")
            .whereField("collaborators.\(userId)", isNotEqualTo: "")

        // Query dictionaries where user is the owner
        let ownerQuery = db
            .collection("dictionaries")
            .whereField("owner", isEqualTo: userId)
        
        // Combine both queries
        let collaboratorListener = collaboratorQuery.addSnapshotListener { [weak self] snapshot, error in
            self?.handleDictionariesSnapshot(snapshot, error: error, userId: userId, isOwnerQuery: false)
        }
        
        let ownerListener = ownerQuery.addSnapshotListener { [weak self] snapshot, error in
            self?.handleDictionariesSnapshot(snapshot, error: error, userId: userId, isOwnerQuery: true)
        }
        
                // Store listeners for cleanup
        listeners["collaborator"] = collaboratorListener
        listeners["owner"] = ownerListener
    }
    
    private func handleDictionariesSnapshot(_ snapshot: QuerySnapshot?, error: Error?, userId: String, isOwnerQuery: Bool) {
        print("📡 [DictionaryService] Snapshot listener triggered (isOwnerQuery: \(isOwnerQuery))")
        
        if let error = error {
            print("❌ [DictionaryService] Error in snapshot listener: \(error.localizedDescription)")
            DispatchQueue.main.async { [weak self] in
                self?.errorMessage = error.localizedDescription
            }
            return
        }
        
        guard let documents = snapshot?.documents else {
            print("📄 [DictionaryService] No documents found in snapshot")
            return
        }
        
        print("📄 [DictionaryService] Found \(documents.count) documents in snapshot")
        
        let dictionaries = documents.compactMap { doc -> SharedDictionary? in
            let data = doc.data()
            print("📄 [DictionaryService] Document \(doc.documentID) data: \(data)")
            
            guard let name = data["name"] as? String,
                  let owner = data["owner"] as? String,
                  let collaborators = data["collaborators"] as? [String: String],
                  let createdAt = data["createdAt"] as? Timestamp else {
                print("❌ [DictionaryService] Failed to parse document \(doc.documentID)")
                return nil
            }
            
            let dictionary = SharedDictionary(
                id: doc.documentID,
                name: name,
                owner: owner,
                collaborators: collaborators,
                createdAt: createdAt.dateValue()
            )
            print("✅ [DictionaryService] Created SharedDictionary: \(dictionary.name)")
            return dictionary
        }
        
        print("📄 [DictionaryService] Parsed \(dictionaries.count) dictionaries")
        
        // Combine dictionaries from both queries and remove duplicates
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            var allDictionaries = self.sharedDictionaries
            
            // Add new dictionaries, avoiding duplicates
            for dictionary in dictionaries {
                if !allDictionaries.contains(where: { $0.id == dictionary.id }) {
                    allDictionaries.append(dictionary)
                }
            }
            
            // Sort by creation date
            self.sharedDictionaries = allDictionaries.sorted { $0.createdAt > $1.createdAt }
            print("📱 [DictionaryService] Updated sharedDictionaries with \(self.sharedDictionaries.count) items")
        }
    }
    
    func listenToSharedDictionaryWords(dictionaryId: String, callback: @escaping ([Word]) -> Void) {
        // Remove existing listener for this dictionary
        stopListening(dictionaryId: dictionaryId)
        let context = coreDataService.context

        let listener = db
            .collection("dictionaries")
            .document(dictionaryId)
            .collection("words")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                guard let documents = snapshot?.documents else {
                    print("❌ [DictionaryService] Error fetching shared dictionary words: \(error?.localizedDescription ?? "Unknown")")
                    return
                }
                
                let words = documents.compactMap {
                    Word.fromFirestoreDictionary($0.data(), id: $0.documentID)
                }

                context.perform {
                    for word in words {
                        let fetchRequest = CDWord.fetchRequest()
                        fetchRequest.predicate = NSPredicate(format: "id == %@", word.id)
                        
                        if let existing = try? context.fetch(fetchRequest).first {
                            if word.timestamp > existing.timestamp ?? Date.distantPast {
                                existing.wordItself = word.wordItself
                                existing.definition = word.definition
                                existing.partOfSpeech = word.partOfSpeech
                                existing.phonetic = word.phonetic
                                try? existing.updateExamples(word.examples)
                                existing.difficultyLevel = Int32(word.difficultyLevel)
                                existing.languageCode = word.languageCode
                                existing.isFavorite = word.isFavorite
                                existing.timestamp = word.timestamp
                                existing.isSynced = true
                            }
                        } else {
                            let entity = word.toCoreDataEntity()
                            // Sync tags separately
                            self.syncTags(word: word, entity: entity)
                        }
                    }
                    
                    try? context.save()
                    callback(words)
                }
            }
        
        listeners[dictionaryId] = listener
    }
    
    func stopListening(dictionaryId: String) {
        listeners[dictionaryId]?.remove()
        listeners.removeValue(forKey: dictionaryId)
    }
    
    func stopAllListeners() {
        listeners.values.forEach { $0.remove() }
        listeners.removeAll()
    }
    
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
    
    // MARK: - Utility Methods
    
    func refreshSharedDictionaries() {
        setupSharedDictionariesListener()
    }
    
    func stopListening() {
        for (_, listener) in listeners {
            listener.remove()
        }
        listeners.removeAll()
    }
    
    func clearError() {
        errorMessage = nil
    }
}

// MARK: - Errors

enum DictionaryError: LocalizedError {
    case invalidInput
    case permissionDenied
    case dictionaryNotFound
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .invalidInput:
            return "Invalid input provided"
        case .permissionDenied:
            return "You don't have permission to perform this action"
        case .dictionaryNotFound:
            return "Dictionary not found"
        case .networkError:
            return "Network error occurred"
        }
    }
} 
