//
//  MyDictionaryApp.swift
//  My Dictionary (macOS)
//
//  Created by Aleksandr Riakhin on 3/29/25.
//

import SwiftUI
import Firebase
import FirebaseAnalytics
import Combine
import UserNotifications
import AppKit
import FirebaseFirestore

@main
struct MyDictionaryApp: App {

    @Environment(\.openWindow) private var openWindow
    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var migrationService = DataMigrationService.shared

    init() {
        // Configure Firebase FIRST
        FirebaseApp.configure()
        
        // Disable Analytics in DEBUG mode
        #if DEBUG
        Analytics.setAnalyticsCollectionEnabled(false)
        print("🔧 [DEBUG] Firebase Analytics disabled")
        #endif
    }

    var body: some Scene {
        Window(Loc.Onboarding.myDictionary, id: WindowID.main) {
            SideBarView()
                .task {
                    if migrationService.needsMigration && !migrationService.isInProgress {
                        try? await migrationService.performMigration()
                    }
                }
                .fontDesign(.rounded)
                .tint(.accent)
                .frame(minWidth: 1000, minHeight: 640)
                .background(Color.systemGroupedBackground)
        }
        .windowResizability(.contentSize)
        .commands {
            SidebarCommands()
            CommandGroup(replacing: CommandGroupPlacement.appInfo) {
                Button {
                    openWindow(id: WindowID.about)
                } label: {
                    Text(Loc.Settings.aboutMyDictionary)
                }
            }
            
            // DO NOT TRANSLATE DEBUG
            #if DEBUG
            CommandGroup(after: CommandGroupPlacement.appInfo) {
                Button {
                    openWindow(id: WindowID.debug)
                } label: {
                    Text("Debug panel")
                }
                .keyboardShortcut("d", modifiers: [.command, .shift])
            }
            #endif
        }
        .defaultSize(width: 900, height: 500)

        Window(Loc.Settings.aboutMyDictionary, id: WindowID.about) {
            AboutAppView()
        }
        .defaultSize(width: 600, height: 650)

        Window(Loc.Analytics.progress, id: WindowID.analytics) {
            AnalyticsView()
        }
        .defaultSize(width: 450, height: 650)

        Settings {
            SettingsView()
        }
        .defaultSize(width: 500, height: 650)

        // DO NOT TRANSLATE DEBUG
        #if DEBUG
        Window("Debug panel", id: WindowID.debug) {
            DebugView()
        }
        .defaultSize(width: 600, height: 800)
        #endif
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Initialize app services and setup
        setupAppServices()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Schedule notifications when app terminates (check for hard words)
        NotificationService.shared.scheduleNotificationsOnAppExit()
        
        // Unregister device token when app terminates
        Task {
            await MessagingService.shared.unregisterCurrentDevice()
        }
    }
    
    func applicationDidResignActive(_ aNotification: Notification) {
        // Schedule notifications when app goes to background (check for hard words)
        NotificationService.shared.scheduleNotificationsOnAppExit()
    }
    
    // MARK: - App Services Setup
    
    private func setupAppServices() {
        // Configure Firestore for offline persistence
        let db = Firestore.firestore()
        let settings = FirestoreSettings()
        settings.isPersistenceEnabled = true
        settings.cacheSizeBytes = FirestoreCacheSizeUnlimited
        db.settings = settings

        // Initialize MessagingService AFTER Firebase is configured
        _ = MessagingService.shared

        // Initialize FeatureToggleService AFTER Firebase is configured
        _ = FeatureToggleService.shared

        // Initialize RemoteConfigService AFTER Firebase is configured
        Task {
            await RemoteConfigService.shared.fetchConfiguration()
            
            // Check and generate AI paywall content if needed (after services are ready)
            await PaywallContentService.shared.forceCheckAndGenerateIfNeeded()
        }

        // Log analytics event
        AnalyticsService.shared.logEvent(.appOpened)

        // DO NOT TRANSLATE DEBUG
        #if DEBUG
        // Debug Firebase configuration
        FirebaseDebugService.shared.checkFirebaseConfiguration()
        FirebaseDebugService.shared.checkAuthenticationStatus()
        #endif

        // Setup notifications
        setupNotifications()
    }
    
    private func setupNotifications() {
        // Notifications are now scheduled when app goes to background/quits
        // No need to schedule on app launch
    }
}
