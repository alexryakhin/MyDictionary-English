//
//  WordCollectionsManager.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 1/27/25.
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
    @Published var hasCollections = false
    
    // MARK: - Private Properties
    
    private let remoteConfigService = RemoteConfigService.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    private init() {
        setupBindings()
    }
    
    // MARK: - Public Methods
    
    /// Fetches word collections from Firebase Remote Config
    func fetchCollections() throws {
        isLoading = true

        do {
            // Parse collections from centralized remote config
            var allCollections: [WordCollection] = []
            
            for key in WordCollectionKeys.allCases {

                if let jsonString = remoteConfigService.getWordCollections(for: key) {
                    debugPrint("🔍 [WordCollectionsManager] Key: \(key.rawValue), JSON length: \(jsonString.count)")
                    let collections = try parseCollections(from: jsonString, languageCode: key.languageCode)
                    allCollections.append(contentsOf: collections)
                    debugPrint("✅ [WordCollectionsManager] Parsed \(collections.count) collections from \(key.rawValue)")
                } else if let jsonString = try? Bundle.main.string(forResource: key.rawValue, withExtension: "json") {
                    let collections = try parseCollections(from: jsonString, languageCode: key.languageCode)
                    allCollections.append(contentsOf: collections)
                    debugPrint("⚠️ [WordCollectionsManager] Parsed \(collections.count) collections from local \(key.rawValue).json")
                } else {
                    debugPrint("⚠️ [WordCollectionsManager] Empty JSON for key: \(key.rawValue)")
                }
            }
            
            // Update published properties
            self.collections = allCollections
            self.hasCollections = !allCollections.isEmpty
            self.isLoading = false

            debugPrint("✅ [WordCollectionsManager] Loaded \(allCollections.count) word collections")
        } catch {
            self.isLoading = false
            throw error
        }
    }
    
    /// Returns collections for a specific language
    func collections(for languageCode: String) -> [WordCollection] {
        return collections.filter { $0.languageCode == languageCode }
    }
    
    /// Returns collections grouped by level
    func collectionsGroupedByLevel() -> [CEFRLevel: [WordCollection]] {
        var grouped: [CEFRLevel: [WordCollection]] = [:]
        
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
    
    /// Returns only featured collections
    func featuredCollections() -> [WordCollection] {
        return collections.filter { $0.isFeatured }
    }
    
    /// Returns featured collections for a specific language
    func featuredCollections(for languageCode: String) -> [WordCollection] {
        return collections.filter { $0.languageCode == languageCode && $0.isFeatured }
    }
    
    /// Returns personalized featured collections based on user's study languages
    func personalizedFeaturedCollections(for userLanguages: [InputLanguage]) -> [WordCollection] {
        // If user has no study languages, return all featured collections
        guard !userLanguages.isEmpty else {
            return featuredCollections()
        }
        
        // Get featured collections for user's languages
        let userLanguageCodes = userLanguages.map { $0.rawValue }
        let personalizedCollections = collections.filter { 
            $0.isFeatured && userLanguageCodes.contains($0.languageCode) 
        }
        
        // If we found collections for user's languages, return them
        if !personalizedCollections.isEmpty {
            return personalizedCollections
        }
        
        // Fallback to all featured collections if no personalized ones found
        return featuredCollections()
    }
    
    /// Returns personalized featured collections for a specific language based on user's study languages
    func personalizedFeaturedCollections(for languageCode: String, userLanguages: [InputLanguage]) -> [WordCollection] {
        // If user has no study languages, return featured collections for the language
        guard !userLanguages.isEmpty else {
            return featuredCollections(for: languageCode)
        }
        
        // Check if the requested language is in user's study languages
        let userLanguageCodes = userLanguages.map { $0.rawValue }
        if userLanguageCodes.contains(languageCode) {
            return featuredCollections(for: languageCode)
        }
        
        // If the language is not in user's study languages, return empty array
        return []
    }
    
    /// Returns collections grouped by featured status
    func collectionsGroupedByFeatured() -> (featured: [WordCollection], regular: [WordCollection]) {
        let featured = collections.filter { $0.isFeatured }
        let regular = collections.filter { !$0.isFeatured }
        return (featured: featured, regular: regular)
    }
    
    /// Force refresh from Firebase Remote Config (bypasses Firebase cache)
    @MainActor
    func forceRefresh() async {
        await remoteConfigService.forceRefresh()
    }
    
    // MARK: - Private Methods

    private func parseCollections(from jsonString: String, languageCode: String) throws -> [WordCollection] {
        guard let data = jsonString.data(using: .utf8) else {
            throw WordCollectionsError.invalidJSONData
        }
        
        do {
            let response = try JSONDecoder().decode(WordCollectionsResponse.self, from: data)
            return response.collections
        } catch {
            debugPrint("❌ [WordCollectionsManager] JSON parsing error: \(error)")
            debugPrint("❌ [WordCollectionsManager] JSON string preview: \(String(jsonString.prefix(200)))...")
            throw WordCollectionsError.parsingError
        }
    }

    private func setupBindings() {
        remoteConfigService.$isInitialized
            .first(where: { $0 })
            .sink { [weak self] _ in
                do {
                    try self?.fetchCollections()
                } catch {
                    debugPrint("❌ [WordCollectionsManager] Failed to fetch word collections: \(error)")
                }
            }
            .store(in: &cancellables)
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
