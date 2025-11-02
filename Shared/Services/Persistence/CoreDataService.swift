//
//  CoreDataService.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import CoreData
import Combine
import CloudKit

final class CoreDataService {

    static let shared = CoreDataService()

    let dataUpdatedPublisher = PassthroughSubject<Void, Never>()

    var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }

    private lazy var persistentContainer: NSPersistentCloudKitContainer = {
        let container = NSPersistentCloudKitContainer(name: "My_Dictionary")
        
        guard let description = container.persistentStoreDescriptions.first else {
            fatalError("No persistent store description found")
        }
        
        // Enable CloudKit sync
        description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        
        // CloudKit configuration
        let cloudKitOptions = NSPersistentCloudKitContainerOptions(containerIdentifier: "iCloud.com.dor.My-Dictionary")
        description.cloudKitContainerOptions = cloudKitOptions
        
        description.shouldMigrateStoreAutomatically = true
        description.shouldInferMappingModelAutomatically = true

        container.loadPersistentStores { description, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        
        // Enable automatic merging of remote changes for real-time sync
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy
        
        return container
    }()

    private var cancellables: Set<AnyCancellable> = []
    private var remoteChangeObserver: NSObjectProtocol?

    private init() {
        setupBindings()
    }
    
    deinit {
        if let observer = remoteChangeObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    func saveContext() throws(CoreError) {
        print("🔍 [CoreDataService] saveContext called")
        let context = persistentContainer.viewContext
        print("📝 [CoreDataService] Context has changes: \(context.hasChanges)")
        
        guard context.hasChanges else {
            print("ℹ️ [CoreDataService] No changes to save")
            return
        }
        
        // Ensure we're on main thread for viewContext (viewContext is main thread)
        // Use performAndWait to ensure synchronous save with proper error handling
        var saveError: Error?
        context.performAndWait {
            do {
                print("💾 [CoreDataService] Attempting to save context")
                try context.save()
                print("✅ [CoreDataService] Context saved successfully")
            } catch {
                print("❌ [CoreDataService] Error saving context: \(error.localizedDescription)")
                saveError = error
            }
        }
        
        // Throw error if save failed
        if let error = saveError {
            print("❌ [CoreDataService] Failed to save context: \(error.localizedDescription)")
            throw .storageError(.saveFailed)
        }
    }

    private func setupBindings() {
        // Listen to CloudKit sync events (setup, import, export) for real-time updates
        // These events indicate when CloudKit sync operations start/complete
        NotificationCenter.default.cloudKitEventPublisher
            .sink { [weak self] notification in
                // Process remote changes immediately (no debounce for low latency)
                self?.handleRemoteChange(notification: notification)
            }
            .store(in: &cancellables)
        
        // Listen to local Core Data saves
        // This notifies when local changes are saved to Core Data
        NotificationCenter.default.coreDataDidSaveObjectIDsPublisher
            .sink { [weak self] _ in
                self?.dataUpdatedPublisher.send()
            }
            .store(in: &cancellables)
        
        // Listen to remote store changes from CloudKit (critical for real-time sync between devices)
        // This is fired when remote changes are merged into the local store
        remoteChangeObserver = NotificationCenter.default.addObserver(
            forName: .NSPersistentStoreRemoteChange,
            object: persistentContainer.persistentStoreCoordinator,
            queue: .main
        ) { [weak self] _ in
            // Note: We ignore the notification parameter - we just need to know remote changes occurred
            self?.handleRemoteStoreChange()
        }
    }
    
    /// Handles CloudKit sync events
    private func handleRemoteChange(notification: Notification) {
        guard let event = notification.userInfo?[NSPersistentCloudKitContainer.eventNotificationUserInfoKey] as? NSPersistentCloudKitContainer.Event,
              event.endDate != nil else {
            // Event is still in progress, no action needed
            return
        }
        
        // Validate event is complete before processing
        
        // Event has finished - notify UI for all event types
        // With automaticallyMergesChangesFromParent = true, changes are already merged
        // No need to refreshAllObjects() - it causes UI flicker and is unnecessary
        switch event.type {
        case .setup, .`import`, .export:
            // Notify UI that sync has completed
            // For .import: data was downloaded from CloudKit
            // For .export: local data was uploaded to CloudKit
            // For .setup: initial CloudKit setup completed
            DispatchQueue.main.async { [weak self] in
                self?.dataUpdatedPublisher.send()
            }
        @unknown default:
            // Handle future event types
            break
        }
    }
    
    /// Handles remote store changes (critical for real-time sync between devices)
    /// This is called when CloudKit syncs changes from another device
    private func handleRemoteStoreChange() {
        // With automaticallyMergesChangesFromParent = true, changes are already merged automatically
        // We should NOT call processPendingChanges() here as it can cause crashes during Core Data's
        // internal change processing if there are invalid relationships (nil objects in sets)
        // Core Data will process changes automatically - we just need to notify the UI
        
        // Notify observers on main thread for low-latency UI updates
        // This is called from main queue already (see setupBindings), so we can send directly
        // Using async to ensure it happens after the current processing completes
        DispatchQueue.main.async { [weak self] in
            self?.dataUpdatedPublisher.send()
        }
    }
    
    // MARK: - UserProfile Methods
    
    func fetchUserProfile() -> CDUserProfile? {
        let fetchRequest: NSFetchRequest<CDUserProfile> = CDUserProfile.fetchRequest()
        do {
            let profiles = try persistentContainer.viewContext.fetch(fetchRequest)
            return profiles.first
        } catch {
            return nil
        }
    }
    
    func hasUserProfile() -> Bool {
        return fetchUserProfile() != nil
    }
    
    func deleteUserProfile() throws {
        guard let profile = fetchUserProfile() else { return }
        persistentContainer.viewContext.delete(profile)
        try saveContext()
    }
}
