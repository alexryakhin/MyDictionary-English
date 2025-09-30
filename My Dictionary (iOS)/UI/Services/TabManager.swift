//
//  TabManager.swift
//  My Dictionary
//
//  Created by Alexander Riakhin on 8/1/25.
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class TabManager: ObservableObject {
    static let shared = TabManager()

    @Published var selectedTab: TabBarItem = .myDictionary

    private init() {}

    func switchToTab(_ tab: TabBarItem, animated: Bool = true) {
        if animated {
            withAnimation {
                selectedTab = tab
            }
        } else {
            selectedTab = tab
        }
    }
}
