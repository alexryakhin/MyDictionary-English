//
//  DictionaryService.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth
import Combine

final class DictionaryService: ObservableObject {

    static let shared = DictionaryService()

    // MARK: - Properties

    @Published var sharedDictionaries: [SharedDictionary] = []
    @Published var sharedWords: [String: [SharedWord]] = [:] // dictionaryId -> [SharedWord]
    @Published var errorMessage: String?

    private let db = Firestore.firestore()
    private let authenticationService = AuthenticationService.shared
    private let wordsProvider = WordsProvider.shared
    private let coreDataService = CoreDataService.shared
    private var listeners: [String: ListenerRegistration] = [:]
    private var cancellables = Set<AnyCancellable>()
    private var collaboratorsCache: [String: [Collaborator]] = [:] // Cache collaborators by dictionary ID
    private let cacheQueue = DispatchQueue(label: "com.mydictionary.collaboratorsCache", attributes: .concurrent)
    private let listenersQueue = DispatchQueue(label: "com.mydictionary.listeners", attributes: .concurrent)

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
        
        // Check if user has Pro subscription for creating shared dictionaries
        guard SubscriptionService.shared.isProUser else {
            print("❌ [DictionaryService] User does not have Pro subscription for creating shared dictionaries")
            throw DictionaryError.subscriptionRequired
        }

        // Get current user info
        let currentUser = Auth.auth().currentUser
        let ownerCollaborator = Collaborator(
            email: currentUser?.email ?? "Unknown",
            displayName: currentUser?.displayName,
            role: .owner
        )

        let dictionaryData: [String: Any] = [
            "name": name,
            "owner": userId,
            "createdAt": Timestamp(date: .now)
        ]

        print("📝 [DictionaryService] Creating dictionary with data: \(dictionaryData)")
        let docRef = db
            .collection("dictionaries")
            .document()
        print("📄 [DictionaryService] Document reference: \(docRef.path)")

        // Create the dictionary document
        try await docRef.setData(dictionaryData)

        // Add the owner as the first collaborator
        // Store with email as document ID for easier lookup in security rules
        let ownerEmail = currentUser?.email ?? "unknown"
        try await docRef
            .collection("collaborators")
            .document(ownerEmail)
            .setData(ownerCollaborator.toFirestoreDictionary())

        print("✅ [DictionaryService] Dictionary created successfully with ID: \(docRef.documentID)")

        // Set up real-time listener for collaborators for the new dictionary
        listenToDictionaryCollaborators(dictionaryId: docRef.documentID)

        return docRef.documentID
    }

    func addCollaborator(dictionaryId: String, email: String, role: CollaboratorRole) async throws {
        guard !dictionaryId.isEmpty, !email.isEmpty, role != .owner else {
            throw DictionaryError.invalidInput
        }

        print("🔍 [DictionaryService] addCollaborator called with dictionaryId: \(dictionaryId), email: \(email), role: \(role)")

        // First, we need to find the user by email
        // This requires a user lookup service or a public user directory
        // For now, we'll require the userId to be provided instead of email
        throw DictionaryError.invalidInput
    }

    func addCollaborator(dictionaryId: String, userId: String, email: String, displayName: String?, role: CollaboratorRole) async throws {
        guard !dictionaryId.isEmpty, !userId.isEmpty, !email.isEmpty, role != .owner else {
            throw DictionaryError.invalidInput
        }

        print("🔍 [DictionaryService] addCollaborator called with dictionaryId: \(dictionaryId), userId: \(userId), email: \(email), role: \(role)")

        let collaborator = Collaborator(
            email: email,
            displayName: displayName,
            role: role
        )

        try await db
            .collection("dictionaries")
            .document(dictionaryId)
            .collection("collaborators")
            .document(email)
            .setData(collaborator.toFirestoreDictionary())

        print("✅ [DictionaryService] Collaborator added successfully")
        
        // Send push notification to the new collaborator
        await sendCollaboratorInvitationNotification(
            to: email,
            dictionaryId: dictionaryId,
            inviterName: authenticationService.displayName ?? "Someone"
        )
    }
    
    // MARK: - Push Notifications
    
    private func sendCollaboratorInvitationNotification(to userEmail: String, dictionaryId: String, inviterName: String) async {
        print("🔔 [DictionaryService] Sending collaborator invitation notification to: \(userEmail)")
        
        do {
            // Get the dictionary name
            let dictionaryDoc = try await db.collection("dictionaries").document(dictionaryId).getDocument()
            guard let dictionaryData = dictionaryDoc.data(),
                  let dictionaryName = dictionaryData["name"] as? String else {
                print("❌ [DictionaryService] Could not get dictionary name for notification")
                return
            }
            
            // Get user's FCM token
            let userDoc = try await db.collection("users").document(userEmail).getDocument()
            guard let userData = userDoc.data(),
                  let fcmToken = userData["fcmToken"] as? String else {
                print("⚠️ [DictionaryService] No FCM token found for user: \(userEmail)")
                return
            }
            
            // Send notification via Firebase Functions
            let notificationData: [String: Any] = [
                "token": fcmToken,
                "title": "New Dictionary Invitation",
                "body": "\(inviterName) added you to '\(dictionaryName)'",
                "data": [
                    "type": "collaborator_invitation",
                    "dictionaryId": dictionaryId,
                    "inviterName": inviterName,
                    "dictionaryName": dictionaryName
                ]
            ]
            
            // Call Firebase Function to send notification
            try await sendPushNotification(notificationData)
            
            print("✅ [DictionaryService] Collaborator invitation notification sent successfully")
            
        } catch {
            print("❌ [DictionaryService] Failed to send collaborator invitation notification: \(error)")
        }
    }
    
    private func sendPushNotification(_ notificationData: [String: Any]) async throws {
        // Use Firebase Functions to send the notification
        // Europe-3 region URL: https://europe-west3-my-dictionary-english.cloudfunctions.net/sendNotification
        
        guard let url = URL(string: "https://europe-west3-my-dictionary-english.cloudfunctions.net/sendNotification") else {
            throw DictionaryError.networkError
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let jsonData = try JSONSerialization.data(withJSONObject: notificationData)
        request.httpBody = jsonData
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw DictionaryError.networkError
        }
        
        if httpResponse.statusCode != 200 {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("❌ [DictionaryService] Firebase Function error: \(errorMessage)")
            throw DictionaryError.networkError
        }
        
        print("✅ [DictionaryService] Push notification sent successfully via Firebase Function")
    }

    func removeCollaborator(dictionaryId: String, email: String) async throws {
        guard !dictionaryId.isEmpty, !email.isEmpty else {
            throw DictionaryError.invalidInput
        }

        print("🔍 [DictionaryService] removeCollaborator called with dictionaryId: \(dictionaryId), email: \(email)")

        let docRef = db
            .collection("dictionaries")
            .document(dictionaryId)
            .collection("collaborators")
            .document(email)

        print("📄 [DictionaryService] Attempting to delete collaborator document: \(docRef.path)")

        try await docRef.delete()

        print("✅ [DictionaryService] Collaborator document deleted from Firestore")

        // Clear the collaborators cache for this dictionary to ensure fresh data
        cacheQueue.async(flags: .barrier) {
            self.collaboratorsCache.removeValue(forKey: dictionaryId)
            print("🧹 [DictionaryService] Cleared collaborators cache for dictionary: \(dictionaryId)")
        }

        // Force a refresh of the shared dictionaries to ensure the UI updates
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            print("🔄 [DictionaryService] Forcing refresh of shared dictionaries listener")
            self?.setupSharedDictionariesListener()
        }

        print("✅ [DictionaryService] Collaborator removed successfully")
    }

    func updateCollaboratorRole(dictionaryId: String, email: String, role: CollaboratorRole) async throws {
        guard !dictionaryId.isEmpty, !email.isEmpty, role != .owner else {
            throw DictionaryError.invalidInput
        }

        try await db
            .collection("dictionaries")
            .document(dictionaryId)
            .collection("collaborators")
            .document(email)
            .updateData([
                "role": role.rawValue
            ])
    }

    func deleteSharedDictionary(dictionaryId: String) async throws {
        guard !dictionaryId.isEmpty else {
            throw DictionaryError.invalidInput
        }
        
        // Check if user has Pro subscription for deleting shared dictionaries
        guard SubscriptionService.shared.isProUser else {
            print("❌ [DictionaryService] User does not have Pro subscription for deleting shared dictionaries")
            throw DictionaryError.subscriptionRequired
        }

        print("🗑️ [DictionaryService] deleteSharedDictionary called with dictionaryId: \(dictionaryId)")

        let batch = db.batch()
        let dictionaryRef = db.collection("dictionaries").document(dictionaryId)

        // Delete all words in the dictionary
        let wordsSnapshot = try await dictionaryRef
            .collection("words")
            .getDocuments()

        print("🗑️ [DictionaryService] Deleting \(wordsSnapshot.documents.count) words from dictionary")
        wordsSnapshot.documents.forEach { doc in
            batch.deleteDocument(doc.reference)
        }

        // Delete all collaborators
        let collaboratorsSnapshot = try await dictionaryRef
            .collection("collaborators")
            .getDocuments()

        print("🗑️ [DictionaryService] Deleting \(collaboratorsSnapshot.documents.count) collaborators from dictionary")
        collaboratorsSnapshot.documents.forEach { doc in
            batch.deleteDocument(doc.reference)
        }

        // Delete the dictionary document
        batch.deleteDocument(dictionaryRef)

        print("🗑️ [DictionaryService] Committing batch deletion to Firestore")
        try await batch.commit()
        print("✅ [DictionaryService] Dictionary deleted from Firestore successfully")

        // Clean up local state immediately
        DispatchQueue.main.async { [weak self] in
            // Remove from shared dictionaries array
            self?.sharedDictionaries.removeAll { $0.id == dictionaryId }
            print("🧹 [DictionaryService] Removed dictionary from local sharedDictionaries array")
            
            // Clear cache for this dictionary
            self?.cacheQueue.async(flags: .barrier) {
                self?.collaboratorsCache.removeValue(forKey: dictionaryId)
                print("🧹 [DictionaryService] Cleared collaborators cache for deleted dictionary")
            }
            
            // Stop listeners for this dictionary
            self?.stopListening(dictionaryId: dictionaryId)
            print("🧹 [DictionaryService] Stopped listeners for deleted dictionary")
            
            // Force a UI update
            DispatchQueue.main.async {
                print("🔄 [DictionaryService] Forcing UI update after dictionary deletion")
            }
        }

        // Force a refresh of the shared dictionaries to ensure the real-time listener picks up the change
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            print("🔄 [DictionaryService] Forcing refresh of shared dictionaries listener after deletion")
            self?.setupSharedDictionariesListener()
        }
    }

    // MARK: - Word Management in Shared Dictionaries

    func addWordToSharedDictionary(dictionaryId: String, word: Word) async throws {
        print("🔍 [DictionaryService] addWordToSharedDictionary called with dictionaryId: \(dictionaryId), word: \(word.wordItself)")

        guard !dictionaryId.isEmpty else {
            print("❌ [DictionaryService] Invalid dictionaryId: \(dictionaryId)")
            throw DictionaryError.invalidInput
        }

        print("📝 [DictionaryService] Creating SharedWord from Word")
        let sharedWord = SharedWord(
            from: word,
            addedByEmail: authenticationService.userEmail ?? "Unknown",
            addedByDisplayName: authenticationService.displayName
        )
        print("📝 [DictionaryService] SharedWord created: \(sharedWord)")

        let docRef = db
            .collection("dictionaries")
            .document(dictionaryId)
            .collection("words")
            .document(sharedWord.id)

        print("📄 [DictionaryService] Word document reference: \(docRef.path)")

        let wordData = sharedWord.toFirestoreDictionary()
        print("📝 [DictionaryService] SharedWord data: \(wordData)")

        do {
            print("📝 [DictionaryService] Attempting to write to Firestore...")
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

        let sharedWord = SharedWord(
            from: word,
            addedByEmail: authenticationService.userEmail ?? "Unknown",
            addedByDisplayName: authenticationService.displayName
        )
        let docRef = db
            .collection("dictionaries")
            .document(dictionaryId)
            .collection("words")
            .document(sharedWord.id)

        try await docRef.updateData(sharedWord.toFirestoreDictionary())
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

        // Remove from in-memory storage
        DispatchQueue.main.async { [weak self] in
            self?.sharedWords[dictionaryId]?.removeAll { $0.id == wordId }
            print("🗑️ [DictionaryService] Removed shared word from in-memory storage: \(wordId)")

            // Clean up orphaned preferences for this word

            print("🧹 [DictionaryService] Cleaned up preferences for deleted shared word: \(wordId)")
        }
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
                    // Only clear if we don't have a user ID (true sign out)
                    if self?.authenticationService.userId == nil {
                        print("❌ [DictionaryService] User signed out, clearing shared dictionaries")
                        DispatchQueue.main.async { [weak self] in
                            self?.sharedDictionaries = []
                        }
                        self?.stopAllListeners()
                    } else {
                        print("⚠️ [DictionaryService] Authentication state is signedOut but user ID exists, keeping dictionaries")
                    }
                case .loading:
                    print("🔄 [DictionaryService] Authentication loading...")
                }
            }
            .store(in: &cancellables)

        // Also check if user is already authenticated when the service starts
        // This handles the case where the app starts with an authenticated user
        if let userId = authenticationService.userId {
            print("🔍 [DictionaryService] User already authenticated with ID: \(userId), setting up listener immediately")
            setupSharedDictionariesListener()
        } else {
            print("🔍 [DictionaryService] No authenticated user found on startup - state: \(authenticationService.authenticationState)")
        }
    }

    // MARK: - Real-time Listeners

    func setupSharedDictionariesListener() {
        print("🔍 [DictionaryService] setupSharedDictionariesListener called")

        // Stop existing listeners first
        stopAllListeners()

        // Check if user is properly authenticated
        // Use userId as the primary check since it's more reliable
        guard let userId = authenticationService.userId else {
            print("❌ [DictionaryService] No user ID available")
            return
        }

        print("👤 [DictionaryService] User ID: \(userId)")
        print("🔍 [DictionaryService] Authentication state: \(authenticationService.authenticationState)")

        // Pre-load cached data first
        preloadCachedSharedDictionaries()

        // Use a single query to get all dictionaries and filter on client side
        // This avoids complex nested field queries that might cause permission issues
        let allDictionariesQuery = db.collection("dictionaries")

        let listener = allDictionariesQuery.addSnapshotListener { [weak self] snapshot, error in
            print("📡 [DictionaryService] Main dictionaries snapshot listener triggered")
            self?.handleDictionariesSnapshot(snapshot, error: error, userId: userId)
        }

        // Store listener for cleanup
        listenersQueue.async(flags: .barrier) {
            self.listeners["dictionaries"] = listener
        }
    }

    // MARK: - Collaborators Listener

    func listenToDictionaryCollaborators(dictionaryId: String) {
        print("🔍 [DictionaryService] listenToDictionaryCollaborators called for dictionary: \(dictionaryId)")

        // Stop existing listener for this dictionary's collaborators
        let collaboratorListenerKey = "\(dictionaryId)_collaborators"
        listenersQueue.sync {
            listeners[collaboratorListenerKey]?.remove()
        }

        let collaboratorsQuery = db
            .collection("dictionaries")
            .document(dictionaryId)
            .collection("collaborators")

        let listener = collaboratorsQuery.addSnapshotListener { [weak self] snapshot, error in
            print("📡 [DictionaryService] Collaborators snapshot listener triggered for dictionary: \(dictionaryId)")
            self?.handleCollaboratorsSnapshot(snapshot, error: error, dictionaryId: dictionaryId)
        }

        listenersQueue.async(flags: .barrier) {
            self.listeners[collaboratorListenerKey] = listener
        }
        print("✅ [DictionaryService] Collaborators listener set up for dictionary: \(dictionaryId)")
    }

    private func preloadCachedSharedDictionaries() {
        print("🔄 [DictionaryService] Pre-loading cached shared dictionaries...")

        let allDictionariesQuery = db.collection("dictionaries")

        // Get cached data first (this will return immediately if cached)
        allDictionariesQuery.getDocuments(source: .cache) { [weak self] snapshot, error in
            if let error = error {
                print("❌ [DictionaryService] Error loading cached dictionaries: \(error.localizedDescription)")
                return
            }

            if let documents = snapshot?.documents, !documents.isEmpty {
                print("📄 [DictionaryService] Found \(documents.count) cached dictionaries")
                self?.handleDictionariesSnapshot(snapshot, error: nil, userId: self?.authenticationService.userId ?? "")
            } else {
                print("📄 [DictionaryService] No cached dictionaries found")
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
            // If no documents, clear all dictionaries
            DispatchQueue.main.async { [weak self] in
                self?.sharedDictionaries = []
                print("🧹 [DictionaryService] Cleared all dictionaries due to empty snapshot")
            }
            return
        }

        print("📄 [DictionaryService] Found \(documents.count) documents in snapshot")
        print("🔍 [DictionaryService] Processing documents for user: \(userId)")
        print("📄 [DictionaryService] Document IDs: \(documents.map { $0.documentID }.joined(separator: ", "))")

        // Process dictionaries and load collaborators for each
        Task {
            var userDictionaries: [SharedDictionary] = []
            let totalDocuments = documents.count
            var processedCount = 0

            for doc in documents {
                guard let dictionary = SharedDictionary.fromFirestoreDictionary(doc.data(), id: doc.documentID) else {
                    print("❌ [DictionaryService] Failed to parse document \(doc.documentID)")
                    processedCount += 1
                    continue
                }

                // Load collaborators for this dictionary
                let collaborators = await loadCollaboratorsForDictionary(dictionaryId: doc.documentID)

                // Check if user has access to this dictionary
                let isOwner = dictionary.owner == userId
                let userEmail = authenticationService.userEmail
                let isCollaborator = userEmail != nil && collaborators.contains { $0.email == userEmail }

                print("🔍 [DictionaryService] Access check for dictionary '\(dictionary.name)':")
                print("   - User ID: \(userId)")
                print("   - User Email: \(userEmail ?? "nil")")
                print("   - Owner: \(dictionary.owner)")
                print("   - Is Owner: \(isOwner)")
                print("   - Collaborators: \(collaborators.map { "\($0.email)(\($0.role))" }.joined(separator: ", "))")
                print("   - Is Collaborator: \(isCollaborator)")

                if isOwner || isCollaborator {
                    var updatedDictionary = dictionary
                    updatedDictionary.collaborators = collaborators
                    userDictionaries.append(updatedDictionary)
                    print("✅ [DictionaryService] User has access to dictionary: \(dictionary.name) (Owner: \(isOwner), Collaborator: \(isCollaborator))")

                    // Set up real-time listener for collaborators
                    self.listenToDictionaryCollaborators(dictionaryId: doc.documentID)
                } else {
                    print("❌ [DictionaryService] User does not have access to dictionary: \(dictionary.name)")
                }

                processedCount += 1
            }

            // Update UI once after processing all dictionaries
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.sharedDictionaries = userDictionaries.sorted { $0.createdAt > $1.createdAt }
                print("📱 [DictionaryService] Final update: \(self.sharedDictionaries.count) dictionaries loaded")
                print("📱 [DictionaryService] Shared dictionaries: \(self.sharedDictionaries.map { "\($0.name) (ID: \($0.id))" }.joined(separator: ", "))")
            }

            print("📄 [DictionaryService] Completed processing \(processedCount)/\(totalDocuments) dictionaries")
        }
    }

    private func loadCollaboratorsForDictionary(dictionaryId: String) async -> [Collaborator] {
        // Check cache first
        let cachedCollaborators = cacheQueue.sync {
            return collaboratorsCache[dictionaryId]
        }
        if let cachedCollaborators = cachedCollaborators {
            print("📄 [DictionaryService] Using cached collaborators for dictionary: \(dictionaryId)")
            return cachedCollaborators
        }

        do {
            let snapshot = try await db
                .collection("dictionaries")
                .document(dictionaryId)
                .collection("collaborators")
                .getDocuments()

            let collaborators = snapshot.documents.compactMap { doc in
                Collaborator.fromFirestoreDictionary(doc.data())
            }

            // Cache the collaborators
            cacheQueue.async(flags: .barrier) {
                self.collaboratorsCache[dictionaryId] = collaborators
            }
            print("📄 [DictionaryService] Cached \(collaborators.count) collaborators for dictionary: \(dictionaryId)")

            return collaborators
        } catch {
            print("❌ [DictionaryService] Error loading collaborators for dictionary \(dictionaryId): \(error.localizedDescription)")
            return []
        }
    }

    func listenToSharedDictionaryWords(dictionaryId: String) {
        print("🔍 [DictionaryService] listenToSharedDictionaryWords called for dictionary: \(dictionaryId)")

        // Stop existing listener for this dictionary
        listenersQueue.sync {
            listeners[dictionaryId]?.remove()
        }

        let wordsQuery = db
            .collection("dictionaries")
            .document(dictionaryId)
            .collection("words")

        // Pre-load cached words first
        preloadCachedSharedWords(dictionaryId: dictionaryId)

        let listener = wordsQuery.addSnapshotListener { [weak self] snapshot, error in
            self?.handleSharedWordsSnapshot(snapshot, error: error, dictionaryId: dictionaryId)
        }

        listenersQueue.async(flags: .barrier) {
            self.listeners[dictionaryId] = listener
        }

        // Also ensure collaborators listener is set up
        listenToDictionaryCollaborators(dictionaryId: dictionaryId)

        print("✅ [DictionaryService] Listener set up for dictionary: \(dictionaryId)")
    }

    private func preloadCachedSharedWords(dictionaryId: String) {
        print("🔄 [DictionaryService] Pre-loading cached shared words for dictionary: \(dictionaryId)")

        let wordsQuery = db
            .collection("dictionaries")
            .document(dictionaryId)
            .collection("words")

        // Get cached data first (this will return immediately if cached)
        wordsQuery.getDocuments(source: .cache) { [weak self] snapshot, error in
            if let error = error {
                print("❌ [DictionaryService] Error loading cached words: \(error.localizedDescription)")
                return
            }

            if let documents = snapshot?.documents, !documents.isEmpty {
                print("📄 [DictionaryService] Found \(documents.count) cached words for dictionary: \(dictionaryId)")
                self?.handleSharedWordsSnapshot(snapshot, error: nil, dictionaryId: dictionaryId)
            } else {
                print("📄 [DictionaryService] No cached words found for dictionary: \(dictionaryId)")
            }
        }
    }

    private func handleSharedWordsSnapshot(_ snapshot: QuerySnapshot?, error: Error?, dictionaryId: String) {
        print("📡 [DictionaryService] Snapshot listener triggered for words in dictionary: \(dictionaryId)")

        if let error = error {
            print("❌ [DictionaryService] Error fetching shared dictionary words: \(error.localizedDescription)")
            return
        }

        guard let documents = snapshot?.documents else {
            print("📄 [DictionaryService] No documents found in snapshot for dictionary: \(dictionaryId)")
            return
        }

        print("📄 [DictionaryService] Found \(documents.count) words in dictionary: \(dictionaryId)")

        let sharedWords = documents.compactMap {
            SharedWord.fromFirestoreDictionary($0.data(), id: $0.documentID)
        }

        print("✅ [DictionaryService] Parsed \(sharedWords.count) shared words from Firestore")

        // Update in-memory storage
        DispatchQueue.main.async { [weak self] in
            let oldWordIds = Set(self?.sharedWords[dictionaryId]?.map { $0.id } ?? [])
            let newWordIds = Set(sharedWords.map { $0.id })

            // Find deleted word IDs
            let deletedWordIds = oldWordIds.subtracting(newWordIds)

            // Clean up preferences for deleted words
            for wordId in deletedWordIds {

                print("🧹 [DictionaryService] Cleaned up preferences for remotely deleted word: \(wordId)")
            }

            self?.sharedWords[dictionaryId] = sharedWords
            print("📱 [DictionaryService] Updated in-memory shared words for dictionary: \(dictionaryId)")
        }
    }

    private func handleCollaboratorsSnapshot(_ snapshot: QuerySnapshot?, error: Error?, dictionaryId: String) {
        print("📡 [DictionaryService] Collaborators snapshot listener triggered for dictionary: \(dictionaryId)")

        if let error = error {
            print("❌ [DictionaryService] Error in collaborators snapshot listener: \(error.localizedDescription)")
            return
        }

        guard let documents = snapshot?.documents else {
            print("📄 [DictionaryService] No collaborator documents found in snapshot for dictionary: \(dictionaryId)")
            return
        }

        print("📄 [DictionaryService] Found \(documents.count) collaborators in dictionary: \(dictionaryId)")

        let collaborators = documents.compactMap { doc in
            Collaborator.fromFirestoreDictionary(doc.data())
        }

        print("✅ [DictionaryService] Parsed \(collaborators.count) collaborators from Firestore")

        // Update the collaborators cache
        cacheQueue.async(flags: .barrier) {
            self.collaboratorsCache[dictionaryId] = collaborators
            print("📄 [DictionaryService] Updated collaborators cache for dictionary: \(dictionaryId) with \(collaborators.count) collaborators")
        }

        // Update the collaborators in the shared dictionaries
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            if let index = self.sharedDictionaries.firstIndex(where: { $0.id == dictionaryId }) {
                self.sharedDictionaries[index].collaborators = collaborators
                print("📱 [DictionaryService] Updated collaborators for dictionary: \(dictionaryId)")

                        // Check if current user lost access to this dictionary
        if let email = self.authenticationService.userEmail {
            let hasAccess = collaborators.contains { $0.email == email } ||
            self.sharedDictionaries[index].owner == self.authenticationService.userId

            print("🔍 [DictionaryService] Access check in collaborators snapshot for dictionary: \(dictionaryId)")
            print("   - User Email: \(email)")
            print("   - User ID: \(self.authenticationService.userId ?? "nil")")
            print("   - Dictionary Owner: \(self.sharedDictionaries[index].owner)")
            print("   - Collaborators: \(collaborators.map { $0.email }.joined(separator: ", "))")
            print("   - Has Access: \(hasAccess)")

            if !hasAccess {
                print("🚫 [DictionaryService] User lost access to dictionary: \(dictionaryId), removing from list")
                self.sharedDictionaries.remove(at: index)
            }
        }
            }
        }
    }

    func stopListening(dictionaryId: String) {
        // Stop words listener
        listenersQueue.sync {
            listeners[dictionaryId]?.remove()
            listeners.removeValue(forKey: dictionaryId)
        }

        // Stop collaborators listener
        let collaboratorListenerKey = "\(dictionaryId)_collaborators"
        listenersQueue.sync {
            listeners[collaboratorListenerKey]?.remove()
            listeners.removeValue(forKey: collaboratorListenerKey)
        }
    }

    func stopAllListeners() {
        listenersQueue.sync {
            listeners.values.forEach { $0.remove() }
            listeners.removeAll()
        }
        cacheQueue.async(flags: .barrier) {
            self.collaboratorsCache.removeAll()
        }
        print("🧹 [DictionaryService] Cleared all listeners and cache")
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
        listenersQueue.sync {
            for (_, listener) in listeners {
                listener.remove()
            }
            listeners.removeAll()
        }
    }

    func clearError() {
        errorMessage = nil
    }
    
    // MARK: - Collaborative Features
    
    func toggleLike(for wordId: String, in dictionaryId: String) async throws {
        guard let userEmail = authenticationService.userEmail else {
            throw DictionaryError.userNotAuthenticated
        }
        
        print("🔍 [DictionaryService] toggleLike called for wordId: \(wordId), dictionaryId: \(dictionaryId)")
        
        let wordRef = db
            .collection("dictionaries")
            .document(dictionaryId)
            .collection("words")
            .document(wordId)
        
        // Get current word data
        let wordDoc = try await wordRef.getDocument()
        guard let wordData = wordDoc.data() else {
            throw DictionaryError.dictionaryNotFound
        }
        
        let currentLikes = wordData["likes"] as? [String: Bool] ?? [:]
        let isCurrentlyLiked = currentLikes[userEmail] ?? false
        
        // Toggle the like status
        var updatedLikes = currentLikes
        updatedLikes[userEmail] = !isCurrentlyLiked
        
        // Update the document
        try await wordRef.updateData([
            "likes": updatedLikes
        ])
        
        // Track analytics
        if updatedLikes[userEmail] == true {
            AnalyticsService.shared.logEvent(.sharedWordLiked)
        } else {
            AnalyticsService.shared.logEvent(.sharedWordUnliked)
        }
        
        print("✅ [DictionaryService] Like toggled successfully for user: \(userEmail)")
    }
    
    func updateDifficulty(for wordId: String, in dictionaryId: String, difficulty: Int) async throws {
        guard let userEmail = authenticationService.userEmail else {
            throw DictionaryError.userNotAuthenticated
        }
        
        guard difficulty >= 0 && difficulty <= 3 else {
            throw DictionaryError.invalidInput
        }
        
        print("🔍 [DictionaryService] updateDifficulty called for wordId: \(wordId), dictionaryId: \(dictionaryId), difficulty: \(difficulty)")
        
        let wordRef = db
            .collection("dictionaries")
            .document(dictionaryId)
            .collection("words")
            .document(wordId)
        
        // Get current word data
        let wordDoc = try await wordRef.getDocument()
        guard let wordData = wordDoc.data() else {
            throw DictionaryError.dictionaryNotFound
        }
        
        let currentDifficulties = wordData["difficulties"] as? [String: Int] ?? [:]
        var updatedDifficulties = currentDifficulties
        updatedDifficulties[userEmail] = difficulty
        
        // Update the document
        try await wordRef.updateData([
            "difficulties": updatedDifficulties
        ])
        
        // Track analytics
        AnalyticsService.shared.logEvent(.sharedWordDifficultyUpdated)
        
        print("✅ [DictionaryService] Difficulty updated successfully for user: \(userEmail)")
    }
    
    func getDifficultyStats(for wordId: String, in dictionaryId: String) async throws -> [String: Int] {
        print("🔍 [DictionaryService] getDifficultyStats called for wordId: \(wordId), dictionaryId: \(dictionaryId)")
        
        let wordRef = db
            .collection("dictionaries")
            .document(dictionaryId)
            .collection("words")
            .document(wordId)
        
        let wordDoc = try await wordRef.getDocument()
        guard let wordData = wordDoc.data() else {
            throw DictionaryError.dictionaryNotFound
        }
        
        let difficulties = wordData["difficulties"] as? [String: Int] ?? [:]
        print("✅ [DictionaryService] Retrieved difficulty stats: \(difficulties)")
        return difficulties
    }
}

// MARK: - Errors

enum DictionaryError: LocalizedError {
    case invalidInput
    case permissionDenied
    case dictionaryNotFound
    case networkError
    case userNotAuthenticated
    case subscriptionRequired

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
        case .subscriptionRequired:
            return "Pro subscription required for this feature"
        }
    }
}
