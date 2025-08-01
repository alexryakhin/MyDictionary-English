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
    
    @Published var selectedTab: TabBarItem = .words

    private init() {}
    
    func switchToTab(_ tab: TabBarItem) {
        selectedTab = tab
    }
} 
