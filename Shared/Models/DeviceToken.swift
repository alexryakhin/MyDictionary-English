//
//  DeviceToken.swift
//  My Dictionary
//
//  Created by Alexander Riakhin on 8/16/25.
//

import Foundation
import FirebaseFirestore

struct DeviceToken: Codable, Identifiable {
    let id: String // FCM token
    let platform: String // iOS, macOS, Android
    let deviceId: String // Unique device identifier
    let appVersion: String
    let lastUpdated: Date
    let isActive: Bool
    
    init(token: String, platform: String, deviceId: String, appVersion: String) {
        self.id = token
        self.platform = platform
        self.deviceId = deviceId
        self.appVersion = appVersion
        self.lastUpdated = Date()
        self.isActive = true
    }
    
    init(token: String, platform: String, deviceId: String, appVersion: String, lastUpdated: Date, isActive: Bool) {
        self.id = token
        self.platform = platform
        self.deviceId = deviceId
        self.appVersion = appVersion
        self.lastUpdated = lastUpdated
        self.isActive = isActive
    }
    
    func toFirestoreDictionary() -> [String: Any] {
        return [
            "id": id,
            "platform": platform,
            "deviceId": deviceId,
            "appVersion": appVersion,
            "lastUpdated": Timestamp(date: lastUpdated),
            "isActive": isActive
        ]
    }
    
    static func fromFirestoreDictionary(_ data: [String: Any]) -> DeviceToken? {
        guard let id = data["id"] as? String,
              let platform = data["platform"] as? String,
              let deviceId = data["deviceId"] as? String,
              let appVersion = data["appVersion"] as? String,
              let lastUpdated = data["lastUpdated"] as? Timestamp,
              let isActive = data["isActive"] as? Bool else {
            return nil
        }
        
        return DeviceToken(
            token: id,
            platform: platform,
            deviceId: deviceId,
            appVersion: appVersion,
            lastUpdated: lastUpdated.dateValue(),
            isActive: isActive
        )
    }
}
