//
//  DeviceTokenService.swift
//  My Dictionary
//
//  Created by Alexander Riakhin on 8/16/25.
//

import Foundation
import FirebaseFirestore
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

final class DeviceTokenService {
    static let shared = DeviceTokenService()
    
    private let db = Firestore.firestore()
    private let authenticationService = AuthenticationService.shared
    
    private init() {}
    
    // MARK: - Device Management
    
    private func getDeviceId() -> String {
        #if os(iOS)
        return UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
        #elseif os(macOS)
        // For macOS, use a combination of hardware info or generate a persistent ID
        if let deviceId = UserDefaults.standard.string(forKey: "DeviceID") {
            return deviceId
        } else {
            let deviceId = UUID().uuidString
            UserDefaults.standard.set(deviceId, forKey: "DeviceID")
            return deviceId
        }
        #else
        return UUID().uuidString
        #endif
    }
    
    private func getAppVersion() -> String {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    }
    
    private func getCurrentPlatform() -> String {
        #if os(iOS)
        return "iOS"
        #elseif os(macOS)
        return "macOS"
        #else
        return "Unknown"
        #endif
    }
    
    // MARK: - Token Management
    
    func registerDeviceToken(_ token: String) async {
        guard let userEmail = authenticationService.userEmail else {
            print("❌ [DeviceTokenService] No user email available for device token registration")
            return
        }
        
        print("🔄 [DeviceTokenService] Registering device token for user: \(userEmail)")
        
        let deviceId = getDeviceId()
        
        do {
            // Check if we already have this token for this device
            let existingDoc = try await db
                .collection("users")
                .document(userEmail)
                .collection("devices")
                .document(deviceId)
                .getDocument()
            
            if existingDoc.exists {
                let existingData = existingDoc.data()
                let existingToken = existingData?["id"] as? String
                
                // Only update if the token has changed
                if existingToken == token {
                    print("ℹ️ [DeviceTokenService] Token unchanged for device: \(deviceId)")
                    return
                }
            }
            
            let deviceToken = DeviceToken(
                token: token,
                platform: getCurrentPlatform(),
                deviceId: deviceId,
                appVersion: getAppVersion()
            )
            
            // Add or update the device token in the user's devices subcollection
            try await db
                .collection("users")
                .document(userEmail)
                .collection("devices")
                .document(deviceToken.deviceId)
                .setData(deviceToken.toFirestoreDictionary(), merge: true)
            
            print("✅ [DeviceTokenService] Device token updated for user: \(userEmail), device: \(deviceToken.deviceId)")
            
        } catch {
            print("❌ [DeviceTokenService] Failed to register device token: \(error)")
        }
    }
    
    func unregisterDeviceToken() async {
        guard let userEmail = authenticationService.userEmail else {
            print("❌ [DeviceTokenService] No user email available for device token unregistration")
            return
        }
        
        let deviceId = getDeviceId()
        
        do {
            // Mark the device as inactive
            try await db
                .collection("users")
                .document(userEmail)
                .collection("devices")
                .document(deviceId)
                .updateData([
                    "isActive": false,
                    "lastUpdated": FieldValue.serverTimestamp()
                ])
            
            print("✅ [DeviceTokenService] Device token unregistered for user: \(userEmail), device: \(deviceId)")
            
        } catch {
            print("❌ [DeviceTokenService] Failed to unregister device token: \(error)")
        }
    }
    
    func getAllActiveTokens(for userEmail: String) async -> [String] {
        do {
            let snapshot = try await db
                .collection("users")
                .document(userEmail)
                .collection("devices")
                .whereField("isActive", isEqualTo: true)
                .getDocuments()
            
            return snapshot.documents.compactMap { doc in
                guard let data = doc.data() as? [String: Any],
                      let deviceToken = DeviceToken.fromFirestoreDictionary(data) else {
                    return nil
                }
                return deviceToken.id
            }
        } catch {
            print("❌ [DeviceTokenService] Failed to get active tokens: \(error)")
            return []
        }
    }
    
    func cleanupInactiveTokens() async {
        guard let userEmail = authenticationService.userEmail else { return }
        
        do {
            // Find devices that haven't been updated in 30 days
            let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
            
            let snapshot = try await db
                .collection("users")
                .document(userEmail)
                .collection("devices")
                .whereField("isActive", isEqualTo: false)
                .whereField("lastUpdated", isLessThan: Timestamp(date: thirtyDaysAgo))
                .getDocuments()
            
            // Delete old inactive devices
            let batch = db.batch()
            for doc in snapshot.documents {
                batch.deleteDocument(doc.reference)
            }
            
            try await batch.commit()
            
            print("✅ [DeviceTokenService] Cleaned up \(snapshot.documents.count) inactive device tokens")
            
        } catch {
            print("❌ [DeviceTokenService] Failed to cleanup inactive tokens: \(error)")
        }
    }
}
