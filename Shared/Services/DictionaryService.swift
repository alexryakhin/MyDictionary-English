//
//  DictionaryService.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import Foundation
import FirebaseFirestore
import FirebaseFunctions
import FirebaseAuth
import Combine

final class DictionaryService: ObservableObject {

    static let shared = DictionaryService()

    private let coreDataService = CoreDataService.shared
    private let db = Firestore.firestore()
    private let functions = Functions.functions(region: "europe-west3")
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
        setupAuthenticationListener()
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
        
        print("🔍 [DictionaryService] addCollaborator called with dictionaryId: \(dictionaryId), email: \(email), role: \(role)")
        
        let data: [String: Any] = [
            "dictionaryId": dictionaryId,
            "email": email,
            "role": role
        ]
        
        // Use Firebase SDK now that IAM permissions are set
        CloudFunctionsService.shared.callFunction("addCollaborator", data: data, forceTokenRefresh: true) { (result: Result<EmptyResponse, Error>) in
            switch result {
            case .success:
                print("✅ [DictionaryService] Collaborator added successfully")
                completion(.success(()))
            case .failure(let error):
                print("❌ [DictionaryService] Failed to add collaborator: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
    }
    
    func removeCollaborator(dictionaryId: String, userId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard !dictionaryId.isEmpty, !userId.isEmpty else {
            completion(.failure(DictionaryError.invalidInput))
            return
        }
        
        print("🔍 [DictionaryService] removeCollaborator called with dictionaryId: \(dictionaryId), userId: \(userId)")
        
        let data: [String: Any] = [
            "dictionaryId": dictionaryId,
            "userId": userId
        ]
        
        // Use Firebase SDK now that IAM permissions are set
        CloudFunctionsService.shared.callFunction("removeCollaborator", data: data) { (result: Result<EmptyResponse, Error>) in
            switch result {
            case .success:
                print("✅ [DictionaryService] Collaborator removed successfully")
                completion(.success(()))
            case .failure(let error):
                print("❌ [DictionaryService] Failed to remove collaborator: \(error.localizedDescription)")
                completion(.failure(error))
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
            print("📤 [DictionaryService] setData completion called for word: \(word.wordItself)")
            
            if let error = error {
                print("❌ [DictionaryService] Error adding word: \(error.localizedDescription)")
                completion(.failure(error))
            } else {
                print("✅ [DictionaryService] Word added successfully to dictionary: \(dictionaryId)")
                print("📄 [DictionaryService] Word document path: \(docRef.path)")
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
    
    // MARK: - Authentication Listener
    
    private func setupAuthenticationListener() {
        print("🔍 [DictionaryService] Setting up authentication listener")
        
        // Listen to authentication state changes
        AuthenticationService.shared.$authenticationState
            .sink { [weak self] state in
                print("🔍 [DictionaryService] Authentication state changed to: \(state)")
                
                switch state {
                case .signedIn:
                    print("✅ [DictionaryService] User signed in, setting up shared dictionaries listener")
                    self?.setupSharedDictionariesListener()
                case .signedOut:
                    print("❌ [DictionaryService] User signed out, clearing shared dictionaries")
                    DispatchQueue.main.async { [weak self] in
                        self?.sharedDictionaries = []
                    }
                    self?.stopAllListeners()
                case .loading:
                    print("🔄 [DictionaryService] Authentication loading...")
                }
            }
            .store(in: &cancellables)
        
        // Also check if user is already authenticated when the service starts
        // This handles the case where the app starts with an authenticated user
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            if let userId = AuthenticationService.shared.userId {
                print("🔍 [DictionaryService] User already authenticated with ID: \(userId), setting up listener")
                self?.setupSharedDictionariesListener()
            } else {
                print("🔍 [DictionaryService] No authenticated user found on startup")
            }
        }
    }
    
    // MARK: - Real-time Listeners
    
    func setupSharedDictionariesListener() {
        print("🔍 [DictionaryService] setupSharedDictionariesListener called")
        
        // Stop existing listeners first
        stopAllListeners()
        
        // Check both userId and authentication state
        guard let userId = AuthenticationService.shared.userId else { 
            print("❌ [DictionaryService] No userId found in AuthenticationService")
            return 
        }
        
        // Additional check to ensure user is properly authenticated
        guard AuthenticationService.shared.authenticationState == .signedIn else {
            print("❌ [DictionaryService] User not properly authenticated. State: \(AuthenticationService.shared.authenticationState)")
            return
        }
        
        print("👤 [DictionaryService] User ID: \(userId)")
        print("✅ [DictionaryService] Authentication state: \(AuthenticationService.shared.authenticationState)")
        
        // Force token refresh before setting up listener
        print("🔄 [DictionaryService] Forcing token refresh...")
        Auth.auth().currentUser?.getIDTokenForcingRefresh(true) { [weak self] token, error in
            if let error = error {
                print("❌ [DictionaryService] Token refresh failed: \(error.localizedDescription)")
                return
            }
            
            if let token = token {
                print("✅ [DictionaryService] Token refreshed successfully")
            } else {
                print("❌ [DictionaryService] No token received after refresh")
                return
            }
            
                            DispatchQueue.main.async {
                    print("📡 [DictionaryService] Setting up listener for dictionaries collection")
                    
                    // Use a single query to get all dictionaries and filter on client side
                    // This avoids complex nested field queries that might cause permission issues
                    let allDictionariesQuery = self?.db
                        .collection("dictionaries")
                    
                    let listener = allDictionariesQuery?.addSnapshotListener { [weak self] snapshot, error in
                        self?.handleDictionariesSnapshot(snapshot, error: error, userId: userId)
                    }
                    
                    // Store listener for cleanup
                    if let listener = listener {
                        self?.listeners["dictionaries"] = listener
                    }
                }
        }
    }
    

    
    private func handleDictionariesSnapshot(_ snapshot: QuerySnapshot?, error: Error?, userId: String) {
        print("📡 [DictionaryService] Snapshot listener triggered")
        
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
        
        // Filter dictionaries on client side based on user permissions
        let userDictionaries = documents.compactMap { doc -> SharedDictionary? in
            let data = doc.data()
            print("📄 [DictionaryService] Document \(doc.documentID) data: \(data)")
            
            guard let name = data["name"] as? String,
                  let owner = data["owner"] as? String,
                  let collaborators = data["collaborators"] as? [String: String],
                  let createdAt = data["createdAt"] as? Timestamp else {
                print("❌ [DictionaryService] Failed to parse document \(doc.documentID)")
                return nil
            }
            
            // Check if user has access to this dictionary
            let isOwner = owner == userId
            let isCollaborator = collaborators[userId] != nil
            
            if isOwner || isCollaborator {
                let dictionary = SharedDictionary(
                    id: doc.documentID,
                    name: name,
                    owner: owner,
                    collaborators: collaborators,
                    createdAt: createdAt.dateValue()
                )
                print("✅ [DictionaryService] User has access to dictionary: \(dictionary.name) (Owner: \(isOwner), Collaborator: \(isCollaborator))")
                return dictionary
            } else {
                print("❌ [DictionaryService] User does not have access to dictionary: \(name)")
                return nil
            }
        }
        
        print("📄 [DictionaryService] User has access to \(userDictionaries.count) dictionaries")
        
        // Update the shared dictionaries
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.sharedDictionaries = userDictionaries.sorted { $0.createdAt > $1.createdAt }
            print("📱 [DictionaryService] Updated sharedDictionaries with \(self.sharedDictionaries.count) items")
        }
    }
    
    func listenToSharedDictionaryWords(dictionaryId: String, callback: @escaping ([Word]) -> Void) {
        print("🔍 [DictionaryService] listenToSharedDictionaryWords called for dictionary: \(dictionaryId)")
        
        // Remove existing listener for this dictionary
        stopListening(dictionaryId: dictionaryId)
        let context = coreDataService.context

        let listener = db
            .collection("dictionaries")
            .document(dictionaryId)
            .collection("words")
            .addSnapshotListener { [weak self] snapshot, error in
                print("📡 [DictionaryService] Snapshot listener triggered for dictionary: \(dictionaryId)")
                
                if let error = error {
                    print("❌ [DictionaryService] Error fetching shared dictionary words: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("📄 [DictionaryService] No documents found in snapshot for dictionary: \(dictionaryId)")
                    return
                }
                
                print("📄 [DictionaryService] Found \(documents.count) words in dictionary: \(dictionaryId)")
                
                let words = documents.compactMap {
                    Word.fromFirestoreDictionary($0.data(), id: $0.documentID)
                }

                print("✅ [DictionaryService] Parsed \(words.count) words from Firestore")

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
                            self?.syncTags(word: word, entity: entity)
                        }
                    }
                    
                    try? context.save()
                    print("📱 [DictionaryService] Calling callback with \(words.count) words")
                    callback(words)
                }
            }
        
        listeners[dictionaryId] = listener
        print("✅ [DictionaryService] Listener set up for dictionary: \(dictionaryId)")
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
    case userNotAuthenticated
    
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
        case .userNotAuthenticated:
            return "User must be authenticated"
        }
    }
} 
