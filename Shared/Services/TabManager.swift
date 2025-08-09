//
//  TabManager.swift
//  My Dictionary
//
//  Created by Alexander Riakhin on 8/1/25.
//

import Foundation
import SwiftUI

@MainActor
final class TabManager: ObservableObject {
    static let shared = TabManager()

    #if os(iOS)
    @Published var selectedTab: TabBarItem = .words
    
    // Tab transition tracking
    @Published private(set) var willSetTab: TabBarItem = .idioms
    @Published private(set) var currentTab: TabBarItem = .words
    @Published private(set) var didSetTab: TabBarItem = .idioms
    #else
    @Published var selectedTab: SidebarItem = .words
    #endif

    private init() {}

    #if os(iOS)
    func switchToTab(_ tab: TabBarItem, animated: Bool = true) {
        // Track transition lifecycle
        willSetTab = tab
        currentTab = selectedTab
        
        if animated {
            withAnimation(.easeInOut(duration: 0.3)) {
                selectedTab = tab
            }
        } else {
            selectedTab = tab
        }
        
        // Use a slight delay to track didSet after transition starts
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            self.didSetTab = tab
        }
    }
    
    func getSlideTransition() -> AnyTransition {
        let tabOrder: [TabBarItem] = [.words, .idioms, .quizzes, .analytics, .settings]
        
        let willSetIndex = tabOrder.firstIndex(of: willSetTab) ?? 0
        let currentIndex = tabOrder.firstIndex(of: currentTab) ?? 0
        let didSetIndex = tabOrder.firstIndex(of: didSetTab) ?? 0

        // Use willSet vs current to determine direction
        if willSetIndex > currentIndex {
            // Moving right (to higher index)
            return .asymmetric(
                insertion: .move(edge: .trailing),
                removal: .move(edge: .leading)
            )
        } else if willSetIndex < currentIndex {
            // Moving left (to lower index)
            return .asymmetric(
                insertion: .move(edge: .leading),
                removal: .move(edge: .trailing)
            )
        } else {
            // Same tab
            return .identity
        }
    }
    #else
    func switchToTab(_ tab: SidebarItem) {
        withAnimation {
            selectedTab = tab
        }
    }
    #endif
}
