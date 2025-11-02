//
//  NotificationCenter+Extension.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import Combine
import CoreData

extension NotificationCenter {
    /// Publisher for Core Data context saves (for local saves)
    /// Uses NSManagedObjectContextDidSave which fires when context saves
    var coreDataDidSaveObjectIDsPublisher: NotificationCenter.Publisher {
        publisher(for: .NSManagedObjectContextDidSave)
    }
    
    /// Publisher for CloudKit sync events (setup, import, export)
    var cloudKitEventPublisher: AnyPublisher<Notification, Never> {
        publisher(for: NSPersistentCloudKitContainer.eventChangedNotification)
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    /// Legacy name for backward compatibility
    var eventChangedPublisher: NotificationCenter.Publisher {
        publisher(for: NSPersistentCloudKitContainer.eventChangedNotification)
    }
}

extension Notification.Name {
    static let authenticationCompleted = Notification.Name("authenticationCompleted")
}
