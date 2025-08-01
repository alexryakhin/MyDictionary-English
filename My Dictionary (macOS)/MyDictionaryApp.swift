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
