//
//  RemoteConfigService.swift
//  My Dictionary
//
//  Created by AI Assistant on 1/27/25.
//

import Foundation
import FirebaseRemoteConfig
import Combine

/// Service responsible for managing API keys and configuration via Firebase Remote Config
final class RemoteConfigService: ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = RemoteConfigService()
    
    // MARK: - Published Properties
    
    @Published var isLoading = false
    @Published var error: Error?
    @Published var isInitialized = false
    
    // MARK: - Private Properties
    
    private let remoteConfig = RemoteConfig.remoteConfig()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Configuration Keys
    
    private enum ConfigKey: String {
        // API Keys
        case openaiAPIKey = "openai_api_key"
        case openaiOrganization = "openai_organization"
        case openaiProjectID = "openai_project_id"
        case speechifyAPIKey = "speechify_api_key"
        
        // Feature Toggles are handled via FeatureToggleItem enum

        // Word Collections are handled via WordCollectionKeys enum
    }
    
    // MARK: - Initialization
    
    private init() {
        setupRemoteConfig()
        // Don't fetch on initialization - let the app control when to fetch
    }
    
    // MARK: - Public Methods
    
    /// Fetches configuration from Firebase Remote Config
    @MainActor
    func fetchConfiguration() async {
        isLoading = true
        error = nil
        
        do {
            // Fetch and activate remote config (uses Firebase's built-in cache)
            let status = try await remoteConfig.fetchAndActivate()
            
            if status == .successFetchedFromRemote {
                print("✅ [RemoteConfigService] Successfully fetched remote config")
            } else {
                print("ℹ️ [RemoteConfigService] Using cached remote config")
            }
            
            // Update initialization state
            self.isInitialized = true
            self.isLoading = false
            
            print("✅ [RemoteConfigService] Configuration loaded successfully")
            
        } catch {
            print("❌ [RemoteConfigService] Failed to fetch configuration: \(error.localizedDescription)")
            self.error = error
            self.isLoading = false
        }
    }
    
    /// Force refresh from Firebase Remote Config (bypasses Firebase cache)
    @MainActor
    func forceRefresh() async {
        // Force fetch from remote (ignores minimumFetchInterval)
        do {
            let status = try await remoteConfig.fetch()
            try await remoteConfig.activate()
            
            if status == .success {
                print("✅ [RemoteConfigService] Force refresh successful")
                await fetchConfiguration()
            } else {
                print("❌ [RemoteConfigService] Force refresh failed with status: \(status)")
            }
        } catch {
            print("❌ [RemoteConfigService] Force refresh error: \(error)")
        }
    }
    
    // MARK: - API Key Accessors
    
    /// Gets the OpenAI API key from Remote Config
    func getOpenAIAPIKey() -> String? {
        return remoteConfig.configValue(forKey: ConfigKey.openaiAPIKey.rawValue).stringValue.nilIfEmpty
    }
    
    /// Gets the OpenAI organization ID from Remote Config
    func getOpenAIOrganization() -> String? {
        return remoteConfig.configValue(forKey: ConfigKey.openaiOrganization.rawValue).stringValue.nilIfEmpty
    }
    
    /// Gets the OpenAI project ID from Remote Config
    func getOpenAIProjectID() -> String? {
        return remoteConfig.configValue(forKey: ConfigKey.openaiProjectID.rawValue).stringValue.nilIfEmpty
    }
    
    /// Gets the Speechify API key from Remote Config
    func getSpeechifyAPIKey() -> String? {
        return remoteConfig.configValue(forKey: ConfigKey.speechifyAPIKey.rawValue).stringValue.nilIfEmpty
    }
    
    /// Checks if RemoteConfig is ready to use
    var isReady: Bool {
        return isInitialized && !isLoading
    }
    
    // MARK: - Feature Toggle Accessors
    
    /// Gets feature toggle status for a specific FeatureToggleItem
    func isFeatureEnabled(_ feature: FeatureToggleItem) -> Bool {
        return remoteConfig.configValue(forKey: feature.rawValue).boolValue
    }
    
    // MARK: - Word Collections Accessors
    
    /// Gets word collections data for a specific WordCollectionKey
    func getWordCollections(for key: WordCollectionKeys) -> String? {
        return remoteConfig.configValue(forKey: key.rawValue).stringValue.nilIfEmpty
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
        
        // Set default values for all configuration keys
        var defaults: [String: NSObject] = [
            // API Keys
            ConfigKey.openaiAPIKey.rawValue: "" as NSObject,
            ConfigKey.openaiOrganization.rawValue: "" as NSObject,
            ConfigKey.openaiProjectID.rawValue: "" as NSObject,
            ConfigKey.speechifyAPIKey.rawValue: "" as NSObject,
            
            // Feature Toggles (use enum defaults)
            // Feature toggles will be added dynamically from FeatureToggleItem enum
        ]
        
        // Add feature toggles defaults from enum
        for feature in FeatureToggleItem.allCases {
            defaults[feature.rawValue] = NSNumber(value: feature.isEnabledByDefault)
        }
        
        // Add word collections defaults for each language if available
        for key in WordCollectionKeys.allCases {
            if let jsonString = try? Bundle.main.string(forResource: key.rawValue, withExtension: "json") {
                defaults[key.rawValue] = jsonString as NSObject
            }
        }
        
        remoteConfig.setDefaults(defaults)
    }
}
