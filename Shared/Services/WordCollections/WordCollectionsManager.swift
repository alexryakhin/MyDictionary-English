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
        loadCachedCollections()
    }
    
    // MARK: - Public Methods
    
    /// Fetches word collections from Firebase Remote Config
    @MainActor
    func fetchCollections() async {
        isLoading = true
        error = nil
        
        do {
            // Fetch and activate remote config
            let status = try await remoteConfig.fetchAndActivate()
            
            if status == .successFetchedFromRemote {
                print("✅ [WordCollectionsManager] Successfully fetched remote config")
            } else {
                print("ℹ️ [WordCollectionsManager] Using cached remote config")
            }
            
            // Parse collections from all available keys
            var allCollections: [WordCollection] = []
            
            for key in WordCollectionKeys.allCases {
                if let jsonString = remoteConfig.configValue(forKey: key.rawValue).stringValue,
                   !jsonString.isEmpty {
                    let collections = try parseCollections(from: jsonString, languageCode: key.languageCode)
                    allCollections.append(contentsOf: collections)
                }
            }
            
            // Update published properties
            self.collections = allCollections
            self.hasCollections = !allCollections.isEmpty
            self.isLoading = false
            
            // Cache collections locally
            cacheCollections(allCollections)
            
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
    
    // MARK: - Private Methods
    
    private func setupRemoteConfig() {
        let settings = RemoteConfigSettings()
        settings.minimumFetchInterval = 3600 // 1 hour
        remoteConfig.configSettings = settings
        
        // Set default values
        let defaults: [String: NSObject] = [:]
        remoteConfig.setDefaults(defaults)
    }
    
    private func parseCollections(from jsonString: String, languageCode: String) throws -> [WordCollection] {
        guard let data = jsonString.data(using: .utf8) else {
            throw WordCollectionsError.invalidJSONData
        }
        
        let response = try JSONDecoder().decode(WordCollectionsResponse.self, from: data)
        return response.collections
    }
    
    private func loadCachedCollections() {
        // Try to load from UserDefaults first
        if let data = UserDefaults.standard.data(forKey: "cached_word_collections"),
           let cachedCollections = try? JSONDecoder().decode([WordCollection].self, from: data) {
            self.collections = cachedCollections
            self.hasCollections = !cachedCollections.isEmpty
            print("📱 [WordCollectionsManager] Loaded \(cachedCollections.count) cached collections")
        }
    }
    
    private func cacheCollections(_ collections: [WordCollection]) {
        if let data = try? JSONEncoder().encode(collections) {
            UserDefaults.standard.set(data, forKey: "cached_word_collections")
            print("💾 [WordCollectionsManager] Cached \(collections.count) collections")
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
