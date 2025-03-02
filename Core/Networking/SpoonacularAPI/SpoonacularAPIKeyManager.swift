//
//  APIKeyManager.swift
//  PureBite
//
//  Created by Aleksandr Riakhin on 9/23/24.
//

protocol SpoonacularAPIKeyManagerInterface {
    /// Retrieve the first available API key that has not been used
    func getCurrentAPIKey() -> String?
    /// Mark the current API key as used
    func markAPIKeyAsUsed(_ key: String)
    /// Check if all API keys are exhausted
    func areAllKeysUsed() -> Bool
}

final class SpoonacularAPIKeyManager: SpoonacularAPIKeyManagerInterface {

    /// Dictionary to store API keys and their usage status
    private var apiKeys: [String: Bool]
    
    init(apiKeys: [String]) {
        // Initialize all keys as unused
        self.apiKeys = apiKeys.reduce(into: [:]) { $0[$1] = false }
    }
    
    func getCurrentAPIKey() -> String? {
        return apiKeys.first { !$0.value }?.key
    }
    
    func markAPIKeyAsUsed(_ key: String) {
        apiKeys[key] = true
    }
    
    func areAllKeysUsed() -> Bool {
        return apiKeys.values.allSatisfy { $0 }
    }
}
