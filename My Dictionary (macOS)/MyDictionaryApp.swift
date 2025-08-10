//
//  MyDictionaryApp.swift
//  My Dictionary (macOS)
//
//  Created by Aleksandr Riakhin on 3/29/25.
//

import SwiftUI
import Firebase

@main
struct MyDictionaryApp: App {

    @Environment(\.openWindow) private var openWindow

    init() {
        FirebaseApp.configure()
        
        // Sync from Firestore on app startup and start real-time listener
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            if let userId = AuthenticationService.shared.userId {
                print("🔄 [App] Triggering initial sync from Firestore for userId: \(userId)")
                Task {
                    do {
                        try await DataSyncService.shared.syncFirestoreToCoreData(userId: userId)
                        print("✅ [App] Initial sync from Firestore completed successfully")
                    } catch {
                        print("❌ [App] Initial sync from Firestore failed: \(error.localizedDescription)")
                    }
                }
                
                // Start real-time listener for existing user
                print("🔊 [App] Starting real-time listener for existing user: \(userId)")
                DataSyncService.shared.startPrivateDictionaryListener(userId: userId)
            } else {
                print("❌ [App] No userId available for initial sync")
            }
        }
    }

    var body: some Scene {
        Window("My Dictionary", id: WindowID.main) {
            MainTabView()
                .font(.system(.body, design: .rounded))
        }
        .windowStyle(TitleBarWindowStyle())
        .windowToolbarStyle(.unifiedCompact)
        .commands {
            CommandGroup(replacing: CommandGroupPlacement.appInfo) {
                Button {
                    openWindow(id: WindowID.about)
                } label: {
                    Text("About My Dictionary")
                }
            }
        }

        Window("About My Dictionary", id: WindowID.about) {
            AboutView()
        }
        .defaultSize(width: 600, height: 600)

        Settings {
            SettingsView()
        }
    }
}
