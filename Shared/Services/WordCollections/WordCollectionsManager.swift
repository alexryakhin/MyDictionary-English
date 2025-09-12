//
//  WordCollectionsManager.swift
//  My Dictionary
//
//  Created by AI Assistant on 1/27/25.
//

import Foundation
import FirebaseRemoteConfig
import Combine

// MARK: - Cache Metadata

private struct CacheMetadata: Codable {
    let timestamp: Date
    let version: String?
    
    var isExpired: Bool {
        Date().timeIntervalSince(timestamp) > 24 * 60 * 60 // 24 hours
    }
}

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
    private let cacheExpirationInterval: TimeInterval = 24 * 60 * 60 // 24 hours
    private let cacheFileName = "word_collections_cache.json"
    private let cacheMetadataFileName = "word_collections_cache_metadata.json"
    
    // MARK: - Initialization
    
    private init() {
        setupRemoteConfig()
        // Load cached collections on initialization
        Task {
            await fetchCollections()
        }
    }
    
    // MARK: - Public Methods
    
    /// Fetches word collections from Firebase Remote Config
    @MainActor
    func fetchCollections() async {
        isLoading = true
        error = nil
        
        // Check if we have valid cached data first
        if let cachedCollections = loadCachedCollections(), !cachedCollections.isEmpty {
            self.collections = cachedCollections
            self.hasCollections = true
            self.isLoading = false
            print("📱 [WordCollectionsManager] Using cached collections (\(cachedCollections.count) items)")
            
            // Still try to fetch fresh data in background if cache is expired
            if isCacheExpired() {
                print("⏰ [WordCollectionsManager] Cache expired, fetching fresh data...")
                await fetchFreshCollections()
            }
            return
        }
        
        // No valid cache, fetch fresh data
        await fetchFreshCollections()
    }
    
    /// Fetches fresh collections from Firebase Remote Config
    @MainActor
    private func fetchFreshCollections() async {
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
                let jsonString = remoteConfig.configValue(forKey: key.rawValue).stringValue
                if !jsonString.isEmpty {
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
    
    /// Clears the cached collections
    func clearCache() {
        guard let cacheURL = getCacheURL(for: cacheFileName),
              let metadataURL = getCacheURL(for: cacheMetadataFileName) else {
            return
        }
        
        try? FileManager.default.removeItem(at: cacheURL)
        try? FileManager.default.removeItem(at: metadataURL)
        
        print("🗑️ [WordCollectionsManager] Cache cleared")
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
        
        do {
            let response = try JSONDecoder().decode(WordCollectionsResponse.self, from: data)
            return response.collections
        } catch {
            print("❌ [WordCollectionsManager] JSON parsing error: \(error)")
            print("❌ [WordCollectionsManager] JSON string preview: \(String(jsonString.prefix(200)))...")
            throw WordCollectionsError.parsingError
        }
    }
    
    private func loadCachedCollections() -> [WordCollection]? {
        guard let cacheURL = getCacheURL(for: cacheFileName),
              let metadataURL = getCacheURL(for: cacheMetadataFileName) else {
            return nil
        }
        
        // Check if cache files exist
        guard FileManager.default.fileExists(atPath: cacheURL.path),
              FileManager.default.fileExists(atPath: metadataURL.path) else {
            return nil
        }
        
        // Load and check metadata
        guard let metadataData = try? Data(contentsOf: metadataURL),
              let metadata = try? JSONDecoder().decode(CacheMetadata.self, from: metadataData) else {
            return nil
        }
        
        // Check if cache is expired
        if metadata.isExpired {
            print("⏰ [WordCollectionsManager] Cache expired, removing old cache files")
            try? FileManager.default.removeItem(at: cacheURL)
            try? FileManager.default.removeItem(at: metadataURL)
            return nil
        }
        
        // Load cached collections
        guard let data = try? Data(contentsOf: cacheURL),
              let cachedCollections = try? JSONDecoder().decode([WordCollection].self, from: data) else {
            return nil
        }
        
        print("📱 [WordCollectionsManager] Loaded \(cachedCollections.count) cached collections (cached at: \(metadata.timestamp))")
        return cachedCollections
    }
    
    private func cacheCollections(_ collections: [WordCollection]) {
        guard let cacheURL = getCacheURL(for: cacheFileName),
              let metadataURL = getCacheURL(for: cacheMetadataFileName) else {
            print("❌ [WordCollectionsManager] Failed to get cache URLs")
            return
        }
        
        // Create cache directory if it doesn't exist
        let cacheDirectory = cacheURL.deletingLastPathComponent()
        try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        
        // Encode and save collections
        guard let data = try? JSONEncoder().encode(collections) else {
            print("❌ [WordCollectionsManager] Failed to encode collections")
            return
        }
        
        do {
            try data.write(to: cacheURL)
            
            // Save metadata
            let metadata = CacheMetadata(timestamp: Date(), version: nil)
            let metadataData = try JSONEncoder().encode(metadata)
            try metadataData.write(to: metadataURL)
            
            print("💾 [WordCollectionsManager] Cached \(collections.count) collections to cache directory")
        } catch {
            print("❌ [WordCollectionsManager] Failed to write cache: \(error)")
        }
    }
    
    private func isCacheExpired() -> Bool {
        guard let metadataURL = getCacheURL(for: cacheMetadataFileName) else {
            return true
        }
        
        guard let metadataData = try? Data(contentsOf: metadataURL),
              let metadata = try? JSONDecoder().decode(CacheMetadata.self, from: metadataData) else {
            return true
        }
        
        return metadata.isExpired
    }
    
    private func getCacheURL(for fileName: String) -> URL? {
        guard let cacheDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            return nil
        }
        return cacheDirectory.appendingPathComponent("WordCollections").appendingPathComponent(fileName)
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
