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
    private let wordsProvider = WordsProvider.shared
    private let authenticationService = AuthenticationService.shared
    private let db = Firestore.firestore()
    private let functions = Functions.functions(region: "europe-west3")
    private var cancellables = Set<AnyCancellable>()
    private var listeners: [String: ListenerRegistration] = [:]

    @Published var sharedDictionaries: [SharedDictionary] = []
    @Published var errorMessage: String?

    struct SharedDictionaryDTO: Codable {
        let name: String
        let owner: String
        let collaborators: [String: CollaboratorRole]
    }

    private init() {
        setupAuthenticationListener()
    }

    // MARK: - Shared Dictionary Management

    @discardableResult
    func createSharedDictionary(userId: String, name: String) async throws -> String {
        print("🔍 [DictionaryService] createSharedDictionary called with userId: \(userId), name: \(name)")

        guard !userId.isEmpty, !name.isEmpty else {
            print("❌ [DictionaryService] Invalid input - userId: \(userId), name: \(name)")
            throw DictionaryError.invalidInput
        }

        let data: [String: Any] = [
            "name": name,
            "owner": userId,
            "collaborators": [userId: CollaboratorRole.owner.rawValue],
            "createdAt": Timestamp(date: .now)
        ]

        print("📝 [DictionaryService] Creating dictionary with data: \(data)")
        let docRef = db
            .collection("dictionaries")
            .document()
        print("📄 [DictionaryService] Document reference: \(docRef.path)")

        try await docRef.setData(data)
        print("✅ [DictionaryService] Dictionary created successfully with ID: \(docRef.documentID)")
        return docRef.documentID
    }

    func addCollaborator(dictionaryId: String, email: String, role: CollaboratorRole) async throws {
        guard !dictionaryId.isEmpty, !email.isEmpty, role != .owner else {
            throw DictionaryError.invalidInput
        }

        print("🔍 [DictionaryService] addCollaborator called with dictionaryId: \(dictionaryId), email: \(email), role: \(role)")

        let data: [String: Any] = [
            "dictionaryId": dictionaryId,
            "email": email,
            "role": role.rawValue
        ]

        // Use Firebase SDK now that IAM permissions are set
        let _: EmptyResponse = try await CloudFunctionsService.shared.callFunction("addCollaborator", data: data, forceTokenRefresh: true)
        print("✅ [DictionaryService] Collaborator added successfully")
    }

    func removeCollaborator(dictionaryId: String, userId: String) async throws {
        guard !dictionaryId.isEmpty, !userId.isEmpty else {
            throw DictionaryError.invalidInput
        }

        print("🔍 [DictionaryService] removeCollaborator called with dictionaryId: \(dictionaryId), userId: \(userId)")

        let data: [String: Any] = [
            "dictionaryId": dictionaryId,
            "userId": userId
        ]

        // Use Firebase SDK now that IAM permissions are set
        let _: EmptyResponse = try await CloudFunctionsService.shared.callFunction("removeCollaborator", data: data)
        print("✅ [DictionaryService] Collaborator removed successfully")
    }

    func updateCollaboratorRole(dictionaryId: String, userId: String, role: CollaboratorRole) async throws {
        guard !dictionaryId.isEmpty, !userId.isEmpty, role != .owner else {
            throw DictionaryError.invalidInput
        }

        try await db
            .collection("dictionaries")
            .document(dictionaryId)
            .updateData([
                "collaborators.\(userId)": role.rawValue
            ])
    }

    func deleteSharedDictionary(dictionaryId: String) async throws {
        guard !dictionaryId.isEmpty else {
            throw DictionaryError.invalidInput
        }

        // Delete all words in the dictionary first
        let snapshot = try await db
            .collection("dictionaries")
            .document(dictionaryId)
            .collection("words")
            .getDocuments()

        let batch = db.batch()

        // Delete all words
        snapshot.documents.forEach { doc in
            batch.deleteDocument(doc.reference)
        }

        // Delete the dictionary document
        batch.deleteDocument(db.collection("dictionaries").document(dictionaryId))

        try await batch.commit()
    }

    // MARK: - Word Management in Shared Dictionaries

    func addWordToSharedDictionary(dictionaryId: String, word: Word) async throws {
        print("🔍 [DictionaryService] addWordToSharedDictionary called with dictionaryId: \(dictionaryId), word: \(word.wordItself)")

        guard !dictionaryId.isEmpty else {
            print("❌ [DictionaryService] Invalid dictionaryId: \(dictionaryId)")
            throw DictionaryError.invalidInput
        }

        let docRef = db
            .collection("dictionaries")
            .document(dictionaryId)
            .collection("words")
            .document(word.id)

        print("📄 [DictionaryService] Word document reference: \(docRef.path)")

        let wordData = word.toFirestoreDictionary()
        print("📝 [DictionaryService] Word data: \(wordData)")

        do {
            try await docRef.setData(wordData)
            print("✅ [DictionaryService] Word added successfully to dictionary: \(dictionaryId)")
            print("📄 [DictionaryService] Word document path: \(docRef.path)")
        } catch {
            print("❌ [DictionaryService] Error adding word: \(error.localizedDescription)")
            throw error
        }
    }

    func updateWordInSharedDictionary(dictionaryId: String, word: Word) async throws {
        guard !dictionaryId.isEmpty else {
            throw DictionaryError.invalidInput
        }

        let docRef = db
            .collection("dictionaries")
            .document(dictionaryId)
            .collection("words")
            .document(word.id)

        try await docRef.updateData(word.toFirestoreDictionary())
    }

    func deleteWordFromSharedDictionary(dictionaryId: String, wordId: String) async throws {
        guard !dictionaryId.isEmpty, !wordId.isEmpty else {
            throw DictionaryError.invalidInput
        }

        let docRef = db
            .collection("dictionaries")
            .document(dictionaryId)
            .collection("words")
            .document(wordId)

        try await docRef.delete()
        try wordsProvider.deleteWord(with: wordId)
    }

    // MARK: - Authentication Listener

    private func setupAuthenticationListener() {
        print("🔍 [DictionaryService] Setting up authentication listener")

        // Listen to authentication state changes
        authenticationService.$authenticationState
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
            if let userId = self?.authenticationService.userId {
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
        guard let userId = authenticationService.userId else {
            print("❌ [DictionaryService] No userId found in AuthenticationService")
            return
        }

        // Additional check to ensure user is properly authenticated
        guard authenticationService.authenticationState == .signedIn else {
            print("❌ [DictionaryService] User not properly authenticated. State: \(authenticationService.authenticationState)")
            return
        }

        print("👤 [DictionaryService] User ID: \(userId)")
        print("✅ [DictionaryService] Authentication state: \(authenticationService.authenticationState)")

        // Use a single query to get all dictionaries and filter on client side
        // This avoids complex nested field queries that might cause permission issues
        let allDictionariesQuery = db.collection("dictionaries")

        let listener = allDictionariesQuery.addSnapshotListener { [weak self] snapshot, error in
            self?.handleDictionariesSnapshot(snapshot, error: error, userId: userId)
        }

        // Store listener for cleanup
        listeners["dictionaries"] = listener
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
            var jsonObject = doc.data()

            guard
                let createdAt = jsonObject.removeValue(forKey: "createdAt") as? Timestamp,
                let data = try? JSONSerialization.data(withJSONObject: jsonObject, options: []),
                let response = try? JSONDecoder().decode(SharedDictionaryDTO.self, from: data)
            else {
                print("❌ [DictionaryService] Failed to parse document \(doc.documentID)")
                return nil
            }

            print("📄 [DictionaryService] Document \(doc.documentID) response: \(response)")

            // Check if user has access to this dictionary
            let isOwner = response.owner == userId
            let isCollaborator = response.collaborators[userId] != nil

            if isOwner || isCollaborator {
                let dictionary = SharedDictionary(
                    id: doc.documentID,
                    name: response.name,
                    owner: response.owner,
                    collaborators: response.collaborators,
                    createdAt: createdAt.dateValue()
                )
                print("✅ [DictionaryService] User has access to dictionary: \(dictionary.name) (Owner: \(isOwner), Collaborator: \(isCollaborator))")
                return dictionary
            } else {
                print("❌ [DictionaryService] User does not have access to dictionary: \(response.name)")
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

    func listenToSharedDictionaryWords(dictionaryId: String) {
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
                    let fetchRequest = CDWord.fetchRequest()
                    let allCoreDataWords: [CDWord] = (try? context.fetch(fetchRequest)) ?? []

                    for word in words {
                        if let existing = allCoreDataWords.first(where: { cdWord in
                            cdWord.id?.uuidString == word.id
                        }) {
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
                                existing.sharedDictionaryId = dictionaryId
                                try? context.save()
                            }
                        } else {
                            let entity = word.toCoreDataEntity()
                            entity.sharedDictionaryId = dictionaryId
                            // Sync tags separately
                            self?.syncTags(word: word, entity: entity)
                            try? context.save()
                        }
                    }

                    // Check for deleted documents in shared dictionary
                    let allLocalSharedWords = allCoreDataWords.filter { cdWord in
                        cdWord.sharedDictionaryId == dictionaryId
                    }
                    print("DEBUG50 1 [DataSyncService] Found \(allLocalSharedWords.count) shared words in local storage")
                    for localWord in allLocalSharedWords {
                        if let wordId = localWord.id?.uuidString, !words.map(\.id).contains(wordId) {
                            print("🗑️ [DataSyncService] Word deleted from shared dictionary, removing from local storage: '\(localWord.wordItself ?? "unknown")' (ID: \(wordId))")
                            context.delete(localWord)
                            try? context.save()
                        }
                    }

                    print("📱 [DictionaryService] Updated Core Data for dictionary: \(dictionaryId)")

                    // Update the WordsProvider
                    DispatchQueue.main.async { [weak self] in
                        self?.wordsProvider.updateSharedWords(for: dictionaryId)
                    }
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
