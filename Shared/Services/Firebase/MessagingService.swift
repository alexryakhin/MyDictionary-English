//
//  MessagingService.swift
//  My Dictionary
//
//  Created by Alexander Riakhin on 8/16/25.
//

import FirebaseMessaging
import Foundation
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

final class MessagingService: NSObject, MessagingDelegate {
    
    static let shared = MessagingService()
    
    private override init() {
        super.init()
        setupMessaging()
    }
    
    // MARK: - Setup
    
    private func setupMessaging() {
        Messaging.messaging().delegate = self
        
        // Check and update token on app launch
        Task {
            await checkAndUpdateToken()
        }
    }
    
    private func checkAndUpdateToken() async {
        #if os(iOS)
        // On iOS, check if APNS token is set first
        if Messaging.messaging().apnsToken == nil {
            print("ℹ️ [MessagingService] APNS token not set yet, skipping FCM token check")
            return
        }
        #endif
        
        guard let currentToken = await getCurrentToken() else { 
            #if os(macOS)
            print("ℹ️ [MessagingService] No FCM token available on macOS - this is normal for development")
            #else
            print("ℹ️ [MessagingService] No FCM token available yet")
            #endif
            return 
        }
        
        // Always register the current token to ensure it's up to date
        await DeviceTokenService.shared.registerDeviceToken(currentToken)
    }
    
    // MARK: - Token Management
    
    func requestNotificationPermission() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .badge, .sound]
            )
            
            if granted {
                await MainActor.run {
                    #if os(iOS)
                    UIApplication.shared.registerForRemoteNotifications()
                    #elseif os(macOS)
                    NSApplication.shared.registerForRemoteNotifications()
                    #endif
                }
            }
            
            return granted
        } catch {
            return false
        }
    }
    
    func getCurrentToken() async -> String? {
        do {
            #if os(macOS)
            // On macOS, we need to handle FCM tokens differently
            // First check if we have a cached token
            if let cachedToken = UDService.fcmToken {
                print("ℹ️ [MessagingService] Using cached FCM token for macOS")
                return cachedToken
            }
            
            // Try to get a new token (this might fail without APNS)
            let token = try await Messaging.messaging().token()
            // Cache the token for future use
            UDService.fcmToken = token
            print("✅ [MessagingService] Retrieved new FCM token for macOS")
            return token
            #else
            return try await Messaging.messaging().token()
            #endif
        } catch {
            #if os(macOS)
            print("ℹ️ [MessagingService] FCM token retrieval failed on macOS: \(error.localizedDescription)")
            // Return cached token if available
            return UDService.fcmToken
            #else
            return nil
            #endif
        }
    }
    
    func refreshToken() async {
        #if os(iOS)
        // On iOS, check if APNS token is set first
        if Messaging.messaging().apnsToken == nil {
            print("ℹ️ [MessagingService] APNS token not set yet, cannot refresh FCM token")
            return
        }
        #endif
        
        do {
            let newToken = try await Messaging.messaging().token()
            #if os(macOS)
            // Cache the token on macOS
            UDService.fcmToken = newToken
            #endif
            await DeviceTokenService.shared.registerDeviceToken(newToken)
        } catch {
            #if os(macOS)
            print("ℹ️ [MessagingService] FCM token refresh failed on macOS: \(error.localizedDescription)")
            // Try to use cached token
            if let cachedToken = UDService.fcmToken {
                await DeviceTokenService.shared.registerDeviceToken(cachedToken)
            }
            #else
            print("❌ [MessagingService] Failed to refresh token: \(error)")
            #endif
        }
    }
    
    func setAPNSToken(_ deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
        
        #if os(iOS)
        // After setting APNS token, refresh FCM token (iOS only)
        Task {
            await refreshToken()
        }
        #endif
    }
    
    func unregisterCurrentDevice() async {
        await DeviceTokenService.shared.unregisterDeviceToken()
    }
    
    #if os(macOS)
    func forceRefreshToken() async {
        print("🔄 [MessagingService] Force refreshing FCM token on macOS")
        // Clear cached token to force a fresh request
        UDService.fcmToken = nil
        await refreshToken()
    }
    #endif
    
    // MARK: - MessagingDelegate
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let token = fcmToken else { return }
        
        Task {
            // Register the device token with the new multi-token system
            await DeviceTokenService.shared.registerDeviceToken(token)
        }
    }
}
