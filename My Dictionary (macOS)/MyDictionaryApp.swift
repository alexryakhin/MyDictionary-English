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

@main
struct MyDictionaryApp: App {

    let diContainer: DIContainer

    init() {
        FirebaseApp.configure()
        diContainer = DIContainer.shared
        diContainer.assemble(assembly: ServicesAssembly())
    }

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .font(.system(.body, design: .rounded))
        }
        .windowStyle(TitleBarWindowStyle())
        .windowToolbarStyle(.unifiedCompact)

        Settings {
            DictionarySettings()
        }
    }
}
