//
//  NavigationManager.swift
//  My Dictionary
//
//  Created by Alexander Riakhin on 8/12/25.
//

import SwiftUI

final class NavigationManager: ObservableObject {

    static let shared = NavigationManager()

    @Published var navigationPath = NavigationPath()

    private init() {}

    func popToRoot() {
        navigationPath = .init()
    }
    
    func navigate(to destination: NavigationDestination) {
        navigationPath.append(destination)
    }
    
    func navigateBack() {
        if !navigationPath.isEmpty {
            navigationPath.removeLast()
        }
    }
}
