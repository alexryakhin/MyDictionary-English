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
        if let deviceId = UDService.deviceID {
            return deviceId
        } else {
            let deviceId = UUID().uuidString
            UDService.deviceID = deviceId
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
        guard let userEmail = authenticationService.userEmail else { return }

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
        } catch {
            print("❌ [DeviceTokenService] Failed to register device token: \(error)")
        }
    }

    func unregisterDeviceToken() async {
        guard let userEmail = authenticationService.userEmail else { return }

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
        } catch {
            print("❌ [DeviceTokenService] Failed to cleanup inactive tokens: \(error)")
        }
    }
}
