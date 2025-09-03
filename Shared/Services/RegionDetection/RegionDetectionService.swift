//
//  RegionDetectionService.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/9/25.
//

import Foundation
import Network
import SwiftUI

// MARK: - Region Detection Service

final class RegionDetectionService: ObservableObject {

    // MARK: - Singleton

    static let shared = RegionDetectionService()

    // MARK: - Published Properties

    @Published private(set) var isInChina: Bool = false
    @Published private(set) var isOffline: Bool = false
    @Published private(set) var isDetectionComplete: Bool = false

    // MARK: - Private Properties

    private let networkMonitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "RegionDetection")
    private var hasAttemptedDetection = false

    // MARK: - Initialization

    private init() {
        setupNetworkMonitoring()
        detectRegion()
    }

    deinit {
        networkMonitor.cancel()
    }

    // MARK: - Public Methods

    /// Determines if features should be shown based on region only
    /// - Returns: True if features should be shown, false otherwise
    func shouldShowFeatures() -> Bool {
        guard isDetectionComplete else { return true }
        return !isInChina
    }

    /// Determines if internet-dependent features should be shown
    /// - Returns: True if internet features should be shown, false otherwise
    func shouldShowInternetFeatures() -> Bool {
        guard isDetectionComplete else { return true }
        return !isOffline
    }

    /// Forces a region detection refresh
    func refreshRegionDetection() {
        detectRegion()
    }

    // MARK: - Private Methods

    private func setupNetworkMonitoring() {
        networkMonitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }

                // Update offline status immediately
                self.isOffline = path.status != .satisfied

                // Only trigger detection if we haven't attempted it yet
                if !hasAttemptedDetection {
                    detectRegion()
                }
            }
        }
        networkMonitor.start(queue: queue)
    }

    private func detectRegion() {
        guard !hasAttemptedDetection else { return }
        hasAttemptedDetection = true

        // Only use IP-based detection - no locale or timezone checks
        let isInChina = detectRegionFromIP()

        DispatchQueue.main.async { [weak self] in
            self?.isInChina = isInChina
            self?.isDetectionComplete = true

            debugPrint("🔍 [RegionDetectionService] IP-based detection complete:")
            debugPrint("   - Result: \(isInChina ? "China IP detected" : "Non-China IP")")
        }
    }

    private func detectRegionFromIP() -> Bool {
        // Use actual IP geolocation to determine if user is physically in China
        // This is the only reliable method - locale and timezone can be changed by user
        Task { @MainActor in
            isInChina = await IPGeolocationService.shared.isIPInChina()
            isDetectionComplete = true
            debugPrint("🔍 [RegionDetectionService] IP detection completed: \(isInChina ? "China" : "Other")")
        }

        // Return false initially, will be updated when IP detection completes
        return false
    }
}

// MARK: - View Modifiers

extension View {
    /// Conditionally hides a view if the user is in China
    /// Use this for features that are not allowed in China (AI features, shared dictionaries, etc.)
    /// - Returns: The view if not in China, an empty view otherwise
    @ViewBuilder
    func hideIfInChina() -> some View {
        if RegionDetectionService.shared.shouldShowFeatures() {
            self
        } else {
            EmptyView()
        }
    }
    
    /// Conditionally hides a view if the user is offline
    /// Use this for features that require internet (AI features, Google backup, etc.)
    /// - Returns: The view if online, an empty view otherwise
    @ViewBuilder
    func hideIfOffline() -> some View {
        if RegionDetectionService.shared.shouldShowInternetFeatures() {
            self
        } else {
            EmptyView()
        }
    }
}
