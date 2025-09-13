//
//  WordCollectionsManager.swift
//  My Dictionary
//
//  Created by AI Assistant on 1/27/25.
//

import Foundation
import FirebaseRemoteConfig
import Combine

/// Manager responsible for fetching and managing word collections from Firebase Remote Config
final class WordCollectionsManager: ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = WordCollectionsManager()
    
    // MARK: - Published Properties
    
    @Published var collections: [WordCollection] = []
    @Published var isLoading = false
    @Published var error: Error?
    @Published var hasCollections = false
    
    // MARK: - Private Properties
    
    private let remoteConfig = RemoteConfig.remoteConfig()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    private init() {
        setupRemoteConfig()
        // Fetch collections on initialization
        Task {
            await fetchCollections()
        }
    }
    
    // MARK: - Methods
    
    /// Fetches word collections from Firebase Remote Config
    @MainActor
    func fetchCollections() async {
        isLoading = true
        error = nil
        
        do {
            // Fetch and activate remote config (uses Firebase's built-in cache)
            let status = try await remoteConfig.fetchAndActivate()
            
            if status == .successFetchedFromRemote {
                print("✅ [WordCollectionsManager] Successfully fetched remote config")
            } else {
                print("ℹ️ [WordCollectionsManager] Using cached remote config")
            }
            
            // Parse collections from all available keys
            var allCollections: [WordCollection] = []
            
            for key in WordCollectionKeys.allCases {
                let jsonString = remoteConfig.configValue(forKey: key.rawValue).stringValue
                print("🔍 [WordCollectionsManager] Key: \(key.rawValue), JSON length: \(jsonString.count)")
                if !jsonString.isEmpty {
                    let collections = try parseCollections(from: jsonString, languageCode: key.languageCode)
                    allCollections.append(contentsOf: collections)
                    print("✅ [WordCollectionsManager] Parsed \(collections.count) collections from \(key.rawValue)")
                } else {
                    print("⚠️ [WordCollectionsManager] Empty JSON for key: \(key.rawValue)")
                }
            }
            
            // Update published properties
            self.collections = allCollections
            self.hasCollections = !allCollections.isEmpty
            self.isLoading = false
            
            print("✅ [WordCollectionsManager] Loaded \(allCollections.count) word collections")
            
        } catch {
            print("❌ [WordCollectionsManager] Failed to fetch collections: \(error.localizedDescription)")
            self.error = error
            self.isLoading = false
        }
    }
    
    /// Returns collections for a specific language
    func collections(for languageCode: String) -> [WordCollection] {
        return collections.filter { $0.languageCode == languageCode }
    }
    
    /// Returns collections grouped by level
    func collectionsGroupedByLevel() -> [WordLevel: [WordCollection]] {
        var grouped: [WordLevel: [WordCollection]] = [:]
        
        for collection in collections {
            if grouped[collection.level] == nil {
                grouped[collection.level] = []
            }
            grouped[collection.level]?.append(collection)
        }
        
        return grouped
    }
    
    /// Returns collections grouped by language
    func collectionsGroupedByLanguage() -> [String: [WordCollection]] {
        var grouped: [String: [WordCollection]] = [:]
        
        for collection in collections {
            if grouped[collection.languageCode] == nil {
                grouped[collection.languageCode] = []
            }
            grouped[collection.languageCode]?.append(collection)
        }
        
        return grouped
    }
    
    /// Force refresh from Firebase Remote Config (bypasses Firebase cache)
    @MainActor
    func forceRefresh() async {
        print("🔄 [WordCollectionsManager] Force refreshing from Firebase...")
        
        // Force fetch from remote (ignores minimumFetchInterval)
        do {
            let status = try await remoteConfig.fetch()
            try await remoteConfig.activate()
            
            if status == .success {
                print("✅ [WordCollectionsManager] Force refresh successful")
                await fetchCollections()
            } else {
                print("❌ [WordCollectionsManager] Force refresh failed with status: \(status)")
            }
        } catch {
            print("❌ [WordCollectionsManager] Force refresh error: \(error)")
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
        
        // Set default values
        let defaults: [String: NSObject] = [:]
        remoteConfig.setDefaults(defaults)
    }
    
    private func parseCollections(from jsonString: String, languageCode: String) throws -> [WordCollection] {
        guard let data = jsonString.data(using: .utf8) else {
            throw WordCollectionsError.invalidJSONData
        }
        
        do {
            let response = try JSONDecoder().decode(WordCollectionsResponse.self, from: data)
            return response.collections
        } catch {
            print("❌ [WordCollectionsManager] JSON parsing error: \(error)")
            print("❌ [WordCollectionsManager] JSON string preview: \(String(jsonString.prefix(200)))...")
            throw WordCollectionsError.parsingError
        }
    }
    
}

// MARK: - Error Types

enum WordCollectionsError: LocalizedError {
    case invalidJSONData
    case networkError
    case parsingError
    
    var errorDescription: String? {
        switch self {
        case .invalidJSONData:
            return "Invalid JSON data received"
        case .networkError:
            return "Network error occurred"
        case .parsingError:
            return "Failed to parse word collections"
        }
    }
}
