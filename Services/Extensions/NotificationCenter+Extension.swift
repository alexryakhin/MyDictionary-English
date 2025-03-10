//
//  NotificationCenter+Extension.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import Combine
import CoreData

extension NotificationCenter {
    var coreDataDidSavePublisher: Publishers.ReceiveOn<NotificationCenter.Publisher, DispatchQueue> {
        return publisher(for: .NSManagedObjectContextDidSave).receive(on: DispatchQueue.main)
    }
    var mergeChangesObjectIDsPublisher: Publishers.ReceiveOn<NotificationCenter.Publisher, DispatchQueue> {
        return publisher(for: .NSManagedObjectContextDidMergeChangesObjectIDs).receive(on: DispatchQueue.main)
    }
    var eventChangedPublisher: Publishers.ReceiveOn<NotificationCenter.Publisher, DispatchQueue> {
        return publisher(for: NSPersistentCloudKitContainer.eventChangedNotification).receive(on: DispatchQueue.main)
    }
}
