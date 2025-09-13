//
//  ReachabilityService.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/9/25.
//

import Foundation
import Network
import SwiftUI

// MARK: - Reachability Service

final class ReachabilityService: ObservableObject {

    // MARK: - Singleton

    static let shared = ReachabilityService()

    // MARK: - Published Properties

    @Published private(set) var isOffline: Bool = false

    // MARK: - Private Properties

    private let networkMonitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "Reachability")

    // MARK: - Initialization

    private init() {
        setupNetworkMonitoring()
    }

    deinit {
        networkMonitor.cancel()
    }

    // MARK: - Methods

    /// Determines if internet-dependent features should be shown
    /// - Returns: True if internet features should be shown, false otherwise
    func shouldShowInternetFeatures() -> Bool {
        return !isOffline
    }

    // MARK: - Private Methods

    private func setupNetworkMonitoring() {
        networkMonitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                
                // Update offline status immediately
                self.isOffline = path.status != .satisfied
                
                debugPrint("🌐 [ReachabilityService] Network status updated: \(path.status == .satisfied ? "Online" : "Offline")")
            }
        }
        networkMonitor.start(queue: queue)
    }
}

// MARK: - View Modifiers

extension View {
    /// Conditionally hides a view if the user is offline
    /// Use this for features that require internet (AI features, Google backup, etc.)
    /// - Returns: The view if online, an empty view otherwise
    @ViewBuilder
    func hideIfOffline() -> some View {
        if ReachabilityService.shared.shouldShowInternetFeatures() {
            self
        } else {
            EmptyView()
        }
    }
}
