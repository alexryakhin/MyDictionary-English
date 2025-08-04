//
//  NotificationCenter+Extension.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import Combine
import CoreData

extension NotificationCenter {
    var coreDataDidSaveObjectIDsPublisher: NotificationCenter.Publisher {
        publisher(for: .NSManagedObjectContextDidSaveObjectIDs)
    }
    var eventChangedPublisher: NotificationCenter.Publisher {
        publisher(for: NSPersistentCloudKitContainer.eventChangedNotification)
    }
}
