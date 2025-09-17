//
//  FeatureToggleService.swift
//  My Dictionary
//
//  Created by AI Assistant on 1/27/25.
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
    
    private let remoteConfig = RemoteConfig.remoteConfig()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    private init() {
        setupRemoteConfig()
        initializeDefaultToggles()
        // Fetch feature toggles on initialization
        Task {
            await fetchFeatureToggles()
        }
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
            // Fetch and activate remote config (uses Firebase's built-in cache)
            let status = try await remoteConfig.fetchAndActivate()
            
            if status == .successFetchedFromRemote {
                print("✅ [FeatureToggleService] Successfully fetched remote config")
            } else {
                print("ℹ️ [FeatureToggleService] Using cached remote config")
            }
            
            // Parse feature toggles from remote config
            var toggles: [FeatureToggleItem: Bool] = [:]
            
            for feature in FeatureToggleItem.allCases {
                let configValue = remoteConfig.configValue(forKey: feature.rawValue)
                let isEnabled = configValue.boolValue
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
        print("🔄 [FeatureToggleService] Force refreshing from Firebase...")
        
        // Force fetch from remote (ignores minimumFetchInterval)
        do {
            let status = try await remoteConfig.fetch()
            try await remoteConfig.activate()
            
            if status == .success {
                print("✅ [FeatureToggleService] Force refresh successful")
                await fetchFeatureToggles()
            } else {
                print("❌ [FeatureToggleService] Force refresh failed with status: \(status)")
            }
        } catch {
            print("❌ [FeatureToggleService] Force refresh error: \(error)")
        }
    }
    
    // MARK: - Private Methods
    
    private func setupRemoteConfig() {
        let settings = RemoteConfigSettings()
        #if DEBUG
        settings.minimumFetchInterval = 0 // No cache in debug mode
        #else
        settings.minimumFetchInterval = 3600 // 1 hour in production
        #endif
        remoteConfig.configSettings = settings
        
        // Set default values for all feature toggles
        var defaults: [String: NSObject] = [:]
        for feature in FeatureToggleItem.allCases {
            defaults[feature.rawValue] = NSNumber(value: feature.isEnabledByDefault)
        }
        remoteConfig.setDefaults(defaults)
    }
    
    private func initializeDefaultToggles() {
        // Initialize with default values
        var defaultToggles: [FeatureToggleItem: Bool] = [:]
        for feature in FeatureToggleItem.allCases {
            defaultToggles[feature] = feature.isEnabledByDefault
        }
        self.featureToggles = defaultToggles
    }
}
