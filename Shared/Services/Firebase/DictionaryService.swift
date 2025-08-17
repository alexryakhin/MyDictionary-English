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

    private let db = Firestore.firestore()
    private let authenticationService = AuthenticationService.shared
    private let wordsProvider = WordsProvider.shared
    private let coreDataService = CoreDataService.shared
    private var listeners: [String: ListenerRegistration] = [:]
    private var cancellables = Set<AnyCancellable>()
    private var collaboratorsCache: [String: [Collaborator]] = [:] // Cache collaborators by dictionary ID
    private let cacheQueue = DispatchQueue(label: "com.mydictionary.collaboratorsCache", attributes: .concurrent)
    private let listenersQueue = DispatchQueue(label: "com.mydictionary.listeners", attributes: .concurrent)
    private var lastUIUpdateTime: [String: Date] = [:] // Track last UI update time per dictionary
    private let uiUpdateDebounceInterval: TimeInterval = 0.5 // Debounce UI updates by 500ms
    private var sharedDictionaryListeners: [String: ListenerRegistration] = [:]
    private var sharedWordListeners: [String: ListenerRegistration] = [:] // Add this line for individual word listeners
    private var hasInitializedSync: [String: Bool] = [:] // Track if we've done initial sync for each user

    private init() {
        setupAuthenticationListener()
    }

    deinit {
        stopAllListeners()
    }

    // MARK: - Shared Dictionary Management

    @discardableResult
    func createSharedDictionary(userId: String, name: String) async throws -> String {
        guard !userId.isEmpty, !name.isEmpty else {
            throw DictionaryError.invalidInput
        }

        // Check if user can create shared dictionaries
        let canCreate = await canUserCreateSharedDictionary(userId: userId)
        guard canCreate else {
            throw DictionaryError.dictionaryLimitReached
        }

        // Get current user info
        let currentUser = Auth.auth().currentUser
        let ownerCollaborator = Collaborator(
            email: currentUser?.email ?? Loc.App.unknown.localized,
            displayName: currentUser?.displayName,
            role: .owner
        )

        let dictionaryData: [String: Any] = [
            "name": name,
            "owner": userId,
            "createdAt": Timestamp(date: .now)
        ]

        let docRef = db
            .collection("dictionaries")
            .document()

        // Create the dictionary document
        try await docRef.setData(dictionaryData)

        // Add the owner as the first collaborator
        // Store with email as document ID for easier lookup in security rules
        let ownerEmail = currentUser?.email ?? Loc.App.unknown.localized
        try await docRef
            .collection("collaborators")
            .document(ownerEmail)
            .setData(ownerCollaborator.toFirestoreDictionary())

        // Set up real-time listener for collaborators for the new dictionary
        listenToDictionaryCollaborators(dictionaryId: docRef.documentID)

        return docRef.documentID
    }

    func addCollaborator(dictionaryId: String, email: String, role: CollaboratorRole) async throws {
        guard !dictionaryId.isEmpty, !email.isEmpty, role != .owner else {
            throw DictionaryError.invalidInput
        }

        // First, we need to find the user by email
        // This requires a user lookup service or a public user directory
        // For now, we'll require the userId to be provided instead of email
        throw DictionaryError.invalidInput
    }

    func addCollaborator(dictionaryId: String, userId: String, email: String, displayName: String?, role: CollaboratorRole) async throws {
        guard !dictionaryId.isEmpty, !userId.isEmpty, !email.isEmpty, role != .owner else {
            throw DictionaryError.invalidInput
        }

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
    }

    func removeCollaborator(dictionaryId: String, email: String) async throws {
        guard !dictionaryId.isEmpty, !email.isEmpty else {
            throw DictionaryError.invalidInput
        }

        let docRef = db
            .collection("dictionaries")
            .document(dictionaryId)
            .collection("collaborators")
            .document(email)

        try await docRef.delete()

        // Clear the collaborators cache for this dictionary to ensure fresh data
        cacheQueue.async(flags: .barrier) {
            self.collaboratorsCache.removeValue(forKey: dictionaryId)
        }

        // Force a refresh of the shared dictionaries to ensure the UI updates
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.setupSharedDictionariesListener()
        }
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

        // Check if user can delete this dictionary
        // Pro users can delete any dictionary they own
        // Free users can only delete their one shared dictionary
        guard let userId = authenticationService.userId else {
            throw DictionaryError.userNotAuthenticated
        }

        // Find the dictionary to check ownership
        guard let dictionary = sharedDictionaries.first(where: { $0.id == dictionaryId }) else {
            throw DictionaryError.dictionaryNotFound
        }

        // Check if user owns this dictionary
        guard dictionary.owner == userId else {
            throw DictionaryError.permissionDenied
        }

        let batch = db.batch()
        let dictionaryRef = db.collection("dictionaries").document(dictionaryId)

        // Delete all words in the dictionary
        let wordsSnapshot = try await dictionaryRef
            .collection("words")
            .getDocuments()

        wordsSnapshot.documents.forEach { doc in
            batch.deleteDocument(doc.reference)
        }

        // Delete all collaborators
        let collaboratorsSnapshot = try await dictionaryRef
            .collection("collaborators")
            .getDocuments()

        collaboratorsSnapshot.documents.forEach { doc in
            batch.deleteDocument(doc.reference)
        }

        // Delete the dictionary document
        batch.deleteDocument(dictionaryRef)

        try await batch.commit()

        // Clean up local state immediately
        DispatchQueue.main.async { [weak self] in
            // Remove from shared dictionaries array
            self?.sharedDictionaries.removeAll { $0.id == dictionaryId }

            // Clear cache for this dictionary
            self?.cacheQueue.async(flags: .barrier) {
                self?.collaboratorsCache.removeValue(forKey: dictionaryId)
            }

            // Stop listeners for this dictionary
            self?.stopListening(dictionaryId: dictionaryId)
        }

        // Force a refresh of the shared dictionaries to ensure the real-time listener picks up the change
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.setupSharedDictionariesListener()
        }
    }

    // MARK: - Word Management in Shared Dictionaries

    func addWordToSharedDictionary(dictionaryId: String, word: Word) async throws {
        guard !dictionaryId.isEmpty else {
            throw DictionaryError.invalidInput
        }

        let sharedWord = SharedWord(
            from: word,
            addedByEmail: authenticationService.userEmail ?? Loc.App.unknown.localized,
            addedByDisplayName: authenticationService.displayName
        )

        let docRef = db
            .collection("dictionaries")
            .document(dictionaryId)
            .collection("words")
            .document(sharedWord.id)

        let wordData = sharedWord.toFirestoreDictionary()

        try await docRef.setData(wordData)
    }

    func updateWordInSharedDictionary(dictionaryId: String, sharedWord: SharedWord) async throws {
        guard !dictionaryId.isEmpty else {
            throw DictionaryError.invalidInput
        }

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

#if os(macOS)
        SideBarManager.shared.selectedSharedWord = nil
#endif

        let docRef = db
            .collection("dictionaries")
            .document(dictionaryId)
            .collection("words")
            .document(wordId)

        try await docRef.delete()

        // Remove from in-memory storage
        DispatchQueue.main.async { [weak self] in
            self?.sharedWords[dictionaryId]?.removeAll { $0.id == wordId }
        }
    }

    // MARK: - Authentication Listener

    private func setupAuthenticationListener() {
        // Listen to authentication state changes
        authenticationService.$authenticationState
            .dropFirst()
            .sink { [weak self] state in
                switch state {
                case .signedIn:
                    self?.setupSharedDictionariesListener()
                case .signedOut:
                    // Only clear if we don't have a user ID (true sign out)
                    if self?.authenticationService.userId == nil {
                        DispatchQueue.main.async { [weak self] in
                            self?.sharedDictionaries = []
                        }
                        self?.stopAllListeners()
                        // Also reset QuizWordsProvider to prevent stale state
                        QuizWordsProvider.shared.reset()
                    }
                case .loading:
                    break
                }
            }
            .store(in: &cancellables)

        // Also check if user is already authenticated when the service starts
        // This handles the case where the app starts with an authenticated user
        if let userId = authenticationService.userId {
            setupSharedDictionariesListener()
        }
    }

    // MARK: - Real-time Listeners

    func setupSharedDictionariesListener() {
        // Stop existing listeners first
        stopAllListeners()

        // Check if user is properly authenticated
        // Use userId as the primary check since it's more reliable
        guard let userId = authenticationService.userId else { return }

        // Pre-load cached data first
        preloadCachedSharedDictionaries()

        // Use a single query to get all dictionaries and filter on client side
        // This avoids complex nested field queries that might cause permission issues
        let allDictionariesQuery = db.collection("dictionaries")

        let listener = allDictionariesQuery.addSnapshotListener { [weak self] snapshot, error in
            self?.handleDictionariesSnapshot(snapshot, error: error, userId: userId)
        }

        // Store listener for cleanup
        listenersQueue.async(flags: .barrier) {
            self.listeners["dictionaries"] = listener
        }
    }

    // MARK: - Collaborators Listener

    func listenToDictionaryCollaborators(dictionaryId: String) {
        let collaboratorListenerKey = "\(dictionaryId)_collaborators"

        // Check if listener already exists for this dictionary's collaborators
        listenersQueue.sync {
            if listeners[collaboratorListenerKey] != nil {
                return
            }
        }

        let collaboratorsQuery = db
            .collection("dictionaries")
            .document(dictionaryId)
            .collection("collaborators")

        let listener = collaboratorsQuery.addSnapshotListener { [weak self] snapshot, error in
            self?.handleCollaboratorsSnapshot(snapshot, error: error, dictionaryId: dictionaryId)
        }

        listenersQueue.async(flags: .barrier) {
            self.listeners[collaboratorListenerKey] = listener
        }
    }

    private func preloadCachedSharedDictionaries() {
        let allDictionariesQuery = db.collection("dictionaries")

        // Get cached data first (this will return immediately if cached)
        allDictionariesQuery.getDocuments(source: .cache) { [weak self] snapshot, error in
            if let error = error { return }

            if let documents = snapshot?.documents,
               !documents.isEmpty {
                self?.handleDictionariesSnapshot(
                    snapshot,
                    error: nil,
                    userId: self?.authenticationService.userId ?? ""
                )
            }
        }
    }

    private func handleDictionariesSnapshot(_ snapshot: QuerySnapshot?, error: Error?, userId: String) {
        if let error = error {
            errorReceived(error)
            return
        }

        guard let documents = snapshot?.documents else {
            // If no documents, clear all dictionaries
            DispatchQueue.main.async { [weak self] in
                self?.sharedDictionaries = []
            }
            return
        }

        // Process dictionaries and load collaborators for each
        Task {
            var userDictionaries: [SharedDictionary] = []
            let totalDocuments = documents.count
            var processedCount = 0

            for doc in documents {
                guard let dictionary = SharedDictionary.fromFirestoreDictionary(doc.data(), id: doc.documentID) else {
                    processedCount += 1
                    continue
                }

                // Load collaborators for this dictionary
                let collaborators = await loadCollaboratorsForDictionary(dictionaryId: doc.documentID)

                // Check if user has access to this dictionary
                let isOwner = dictionary.owner == userId
                let userEmail = authenticationService.userEmail
                let isCollaborator = userEmail != nil && collaborators.contains { $0.email == userEmail }

                if isOwner || isCollaborator {
                    var updatedDictionary = dictionary
                    updatedDictionary.collaborators = collaborators
                    userDictionaries.append(updatedDictionary)

                    // Set up real-time listener for collaborators
                    self.listenToDictionaryCollaborators(dictionaryId: doc.documentID)
                    self.listenToSharedDictionaryWords(dictionaryId: doc.documentID)
                }

                processedCount += 1
            }

            // Update UI once after processing all dictionaries
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                self.sharedDictionaries = userDictionaries.sorted { $0.createdAt > $1.createdAt }
            }
        }
    }

    private func loadCollaboratorsForDictionary(dictionaryId: String) async -> [Collaborator] {
        // Check cache first
        let cachedCollaborators = cacheQueue.sync {
            return collaboratorsCache[dictionaryId]
        }
        if let cachedCollaborators = cachedCollaborators {
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
            return collaborators
        } catch {
            return []
        }
    }

    func listenToSharedDictionaryWords(dictionaryId: String) {
        // Check if listener already exists for this dictionary
        listenersQueue.sync {
            if listeners[dictionaryId] != nil { return }
        }

        let wordsQuery = db
            .collection("dictionaries")
            .document(dictionaryId)
            .collection("words")

        let listener = wordsQuery.addSnapshotListener { [weak self] snapshot, error in
            self?.handleSharedWordsSnapshot(snapshot, error: error, dictionaryId: dictionaryId)
        }

        listenersQueue.async(flags: .barrier) {
            self.listeners[dictionaryId] = listener
        }

        // Also ensure collaborators listener is set up
        listenToDictionaryCollaborators(dictionaryId: dictionaryId)
    }

    private func preloadCachedSharedWords(dictionaryId: String) {
        let wordsQuery = db
            .collection("dictionaries")
            .document(dictionaryId)
            .collection("words")

        // Get cached data first (this will return immediately if cached)
        wordsQuery.getDocuments(source: .cache) { [weak self] snapshot, error in
            if let error = error { return }

            if let documents = snapshot?.documents, !documents.isEmpty {
                // Don't trigger UI updates during preload - just cache the data
                self?.cacheSharedWords(documents, dictionaryId: dictionaryId)
            }
        }
    }

    private func cacheSharedWords(_ documents: [QueryDocumentSnapshot], dictionaryId: String) {
        let sharedWords = documents.compactMap {
            SharedWord.fromFirestoreDictionary($0.data(), id: $0.documentID)
        }

        // Update in-memory storage without triggering UI updates
        DispatchQueue.main.async { [weak self] in
            self?.sharedWords[dictionaryId] = sharedWords
        }
    }

    private func handleSharedWordsSnapshot(_ snapshot: QuerySnapshot?, error: Error?, dictionaryId: String) {
        if let error = error { return }
        guard let documents = snapshot?.documents else { return }

        let sharedWords = documents.compactMap {
            SharedWord.fromFirestoreDictionary($0.data(), id: $0.documentID)
        }

        // Update in-memory storage
        DispatchQueue.main.async { [weak self] in
            let oldWordIds = Set(self?.sharedWords[dictionaryId]?.map { $0.id } ?? [])
            let newWordIds = Set(sharedWords.map { $0.id })

            // Find deleted word IDs
            let deletedWordIds = oldWordIds.subtracting(newWordIds)
            self?.sharedWords[dictionaryId] = sharedWords
        }
    }

    private func handleCollaboratorsSnapshot(_ snapshot: QuerySnapshot?, error: Error?, dictionaryId: String) {
        if let error = error { return }
        guard let documents = snapshot?.documents else { return }

        let collaborators = documents.compactMap { doc in
            Collaborator.fromFirestoreDictionary(doc.data())
        }

        // Update the collaborators cache
        cacheQueue.async(flags: .barrier) {
            self.collaboratorsCache[dictionaryId] = collaborators
        }

        // Update the collaborators in the shared dictionaries with debouncing
        let now = Date()
        let lastUpdate = lastUIUpdateTime[dictionaryId] ?? Date.distantPast

        if now.timeIntervalSince(lastUpdate) >= uiUpdateDebounceInterval {
            lastUIUpdateTime[dictionaryId] = now

            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }

                if let index = self.sharedDictionaries.firstIndex(where: { $0.id == dictionaryId }) {
                    self.sharedDictionaries[index].collaborators = collaborators

                    // Check if current user lost access to this dictionary
                    if let email = self.authenticationService.userEmail {
                        let hasAccess = collaborators.contains { $0.email == email } ||
                        self.sharedDictionaries[index].owner == self.authenticationService.userId

                        if !hasAccess {
                            self.sharedDictionaries.remove(at: index)
                        }
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

        // Clear cache for this dictionary
        cacheQueue.async(flags: .barrier) {
            self.collaboratorsCache.removeValue(forKey: dictionaryId)
        }
        lastUIUpdateTime.removeValue(forKey: dictionaryId)

        // Clear shared words for this dictionary
        DispatchQueue.main.async { [weak self] in
            self?.sharedWords.removeValue(forKey: dictionaryId)
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
        lastUIUpdateTime.removeAll()

        // Stop all shared word listeners
        stopAllSharedWordListeners()

        // Clear shared words cache
        DispatchQueue.main.async { [weak self] in
            self?.sharedWords.removeAll()
        }
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

    /// Checks if a user can create shared dictionaries
    /// Free users can create 1 shared dictionary, Pro users can create unlimited
    private func canUserCreateSharedDictionary(userId: String) async -> Bool {
        // First check if user can access Pro features (must be authenticated)
        guard authenticationService.isSignedIn else { return false }

        let userOwnedDictionaries = sharedDictionaries.filter { $0.owner == userId }
        let canCreate = SubscriptionService.shared.canCreateMoreSharedDictionaries(currentCount: userOwnedDictionaries.count)

        return canCreate
    }

    /// Public method to check if user can create more shared dictionaries
    /// Returns true if user can create, false if limit reached
    func canCreateMoreSharedDictionaries() -> Bool {
        guard let userId = authenticationService.userId else {
            return false
        }

        let userOwnedDictionaries = sharedDictionaries.filter { $0.owner == userId }
        return SubscriptionService.shared.canCreateMoreSharedDictionaries(currentCount: userOwnedDictionaries.count)
    }

    /// Returns the number of shared dictionaries the user owns
    func getUserOwnedDictionaryCount() -> Int {
        guard let userId = authenticationService.userId else {
            return 0
        }

        return sharedDictionaries.filter { $0.owner == userId }.count
    }

    func stopListening() {
        listenersQueue.sync {
            for (_, listener) in listeners {
                listener.remove()
            }
            listeners.removeAll()
        }
    }

    // MARK: - Collaborative Features

    func toggleLike(for wordId: String, in dictionaryId: String) async throws {
        guard let userEmail = authenticationService.userEmail else {
            throw DictionaryError.userNotAuthenticated
        }

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
    }

    func updateDifficulty(for wordId: String, in dictionaryId: String, difficulty: Int) async throws {
        guard let userEmail = authenticationService.userEmail else {
            throw DictionaryError.userNotAuthenticated
        }

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
    }

    func getDifficultyStats(for wordId: String, in dictionaryId: String) async throws -> [String: Int] {
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
        return difficulties
    }

    func stopAllSharedDictionaryListeners() {
        sharedDictionaryListeners.values.forEach { $0.remove() }
        sharedDictionaryListeners.removeAll()
    }

    func pauseAllListeners() {
        sharedDictionaryListeners.values.forEach { $0.remove() }
        sharedDictionaryListeners.removeAll()
        sharedWordListeners.values.forEach { $0.remove() }
        sharedWordListeners.removeAll()
        listeners.values.forEach { $0.remove() }
        listeners.removeAll()
    }

    func resumeAllListeners() {
        // Re-establish listeners for all active dictionaries
        for dictionary in sharedDictionaries {
            listenToSharedDictionaryWords(dictionaryId: dictionary.id)
            listenToDictionaryCollaborators(dictionaryId: dictionary.id)
        }
    }

    // MARK: - Individual Shared Word Listeners

    func startSharedWordListener(dictionaryId: String, wordId: String, onUpdate: @escaping (SharedWord?) -> Void) {
        // Remove existing listener if any
        stopSharedWordListener(dictionaryId: dictionaryId, wordId: wordId)

        let listenerKey = "\(dictionaryId)_\(wordId)"
        let docRef = db
            .collection("dictionaries")
            .document(dictionaryId)
            .collection("words")
            .document(wordId)

        let listener = docRef.addSnapshotListener { snapshot, error in
            guard let document = snapshot else {
                onUpdate(nil)
                return
            }

            guard let data = document.data() else {
                onUpdate(nil)
                return
            }

            if let sharedWord = SharedWord.fromFirestoreDictionary(data, id: wordId) {
                onUpdate(sharedWord)
            } else {
                onUpdate(nil)
            }
        }

        // Store the listener for cleanup
        sharedWordListeners[listenerKey] = listener
    }

    func stopSharedWordListener(dictionaryId: String, wordId: String) {
        let listenerKey = "\(dictionaryId)_\(wordId)"
        sharedWordListeners[listenerKey]?.remove()
        sharedWordListeners.removeValue(forKey: listenerKey)
    }

    func stopAllSharedWordListeners() {
        sharedWordListeners.values.forEach { $0.remove() }
        sharedWordListeners.removeAll()
    }

    private func errorReceived(_ error: Error) {
        Task { @MainActor in
            AlertCenter.shared.showAlert(with: .error(message: error.localizedDescription))
        }
    }
}

// MARK: - Errors

enum DictionaryError: Error, LocalizedError {
    case invalidInput
    case permissionDenied
    case dictionaryNotFound
    case networkError
    case userNotAuthenticated
    case dictionaryLimitReached

    var errorDescription: String? {
        switch self {
        case .invalidInput:
            return Loc.Errors.invalidInputProvided.localized
        case .permissionDenied:
            return Loc.Errors.permissionDenied.localized
        case .dictionaryNotFound:
            return Loc.Errors.dictionaryNotFound.localized
        case .networkError:
            return Loc.Errors.networkErrorOccurred.localized
        case .userNotAuthenticated:
            return Loc.Errors.userNotAuthenticated.localized
        case .dictionaryLimitReached:
            return Loc.Errors.dictionaryLimitReached.localized
        }
    }
}
