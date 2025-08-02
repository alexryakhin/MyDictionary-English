//
//  NavigationManager.swift
//  My Dictionary
//
//  Created by Alexander Riakhin on 8/1/25.
//

import Foundation
import SwiftUI

@MainActor
final class NavigationManager: ObservableObject {
    static let shared = NavigationManager()

    #if os(iOS)
    @Published var selectedTab: TabBarItem = .words
    #else
    @Published var selectedTab: SidebarItem = .words
    #endif

    private init() {}

    #if os(iOS)
    func switchToTab(_ tab: TabBarItem) {
        selectedTab = tab
    }
    #else
    func switchToTab(_ tab: SidebarItem) {
        selectedTab = tab
    }
    #endif
}
