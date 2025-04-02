//
//  MyDictionaryApp.swift
//  My Dictionary (macOS)
//
//  Created by Aleksandr Riakhin on 3/29/25.
//

import SwiftUI
import Shared
import Firebase
import UserInterface__macOS_
import CoreUserInterface__macOS_

@main
struct MyDictionaryApp: App {

    @Environment(\.openWindow) private var openWindow

    let diContainer: DIContainer

    init() {
        FirebaseApp.configure()
        diContainer = DIContainer.shared
        diContainer.assemble(assembly: ServicesAssembly())
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
