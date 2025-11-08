//
//  FeatureToggleService.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 1/27/25.
//

import Foundation
import FirebaseRemoteConfig
import Combine

/// Service responsible for managing feature toggles via Firebase Remote Config
final class FeatureToggleService: ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = FeatureToggleService()
    
    // MARK: - Published Properties
    
    @Published var featureToggles: [FeatureToggleItem: Bool] = [:]
    @Published var isLoading = false
    @Published var error: Error?
    
    // MARK: - Private Properties
    
    private let remoteConfigService = RemoteConfigService.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    private init() {
        initializeDefaultToggles()
        observeRemoteConfigReadiness()
        // Fetch feature toggles on initialization
        Task {
            await fetchFeatureToggles()
        }
    }
    private func observeRemoteConfigReadiness() {
        if remoteConfigService.isReady {
            Task { @MainActor [weak self] in
                await self?.fetchFeatureToggles()
            }
        }
        
        remoteConfigService.readinessPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                Task { @MainActor in
                    await self?.fetchFeatureToggles()
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    
    /// Checks if a specific feature toggle is enabled
    func isEnabled(_ feature: FeatureToggleItem) -> Bool {
        return featureToggles[feature] ?? feature.isEnabledByDefault
    }
    
    /// Fetches feature toggles from Firebase Remote Config
    @MainActor
    func fetchFeatureToggles() async {
        isLoading = true
        error = nil
        
        do {
            // Wait for RemoteConfigService to be ready
            guard remoteConfigService.isReady else {
                print("⚠️ [FeatureToggleService] RemoteConfigService not ready, using defaults")
                self.isLoading = false
                return
            }
            
            // Parse feature toggles from centralized remote config
            var toggles: [FeatureToggleItem: Bool] = [:]
            
            for feature in FeatureToggleItem.allCases {
                let isEnabled = remoteConfigService.isFeatureEnabled(feature)
                toggles[feature] = isEnabled
                print("🔧 [FeatureToggleService] \(feature.rawValue): \(isEnabled)")
            }
            
            // Update published properties
            self.featureToggles = toggles
            self.isLoading = false
            
            print("✅ [FeatureToggleService] Loaded \(toggles.count) feature toggles")
            
        } catch {
            print("❌ [FeatureToggleService] Failed to fetch feature toggles: \(error.localizedDescription)")
            self.error = error
            self.isLoading = false
        }
    }
    
    /// Force refresh from Firebase Remote Config (bypasses Firebase cache)
    @MainActor
    func forceRefresh() async {
        await remoteConfigService.forceRefresh()
    }
    
    // MARK: - Private Methods
    
    
    private func initializeDefaultToggles() {
        // Initialize with default values
        var defaultToggles: [FeatureToggleItem: Bool] = [:]
        for feature in FeatureToggleItem.allCases {
            defaultToggles[feature] = feature.isEnabledByDefault
        }
        self.featureToggles = defaultToggles
    }
}
