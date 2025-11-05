//
//  MusicSongTagService.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin
//

import Foundation
import FirebaseFirestore

/// Service for loading song tags from Firestore
/// Caches tags locally for offline recommendation
final class MusicSongTagService {
    
    static let shared = MusicSongTagService()
    
    private let db = Firestore.firestore()
    private var cachedTags: [String: SongTag] = [:]
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// Load song tag from Firestore cache or fetch if not cached
    /// - Parameter songId: The song ID
    /// - Returns: SongTag if found, nil otherwise
    func getTag(for songId: String) async -> SongTag? {
        // Check cache first
        if let cached = cachedTags[songId] {
            return cached
        }
        
        // Fetch from Firestore
        do {
            let tag = try await fetchTagFromFirestore(songId: songId)
            if let tag = tag {
                cachedTags[songId] = tag
            }
            return tag
        } catch {
            print("⚠️ [MusicSongTagService] Failed to fetch tag for song \(songId): \(error)")
            return nil
        }
    }
    
    /// Load multiple song tags from Firestore
    /// - Parameter songIds: Array of song IDs
    /// - Returns: Dictionary mapping song ID to SongTag
    func getTags(for songIds: [String]) async -> [String: SongTag] {
        var tags: [String: SongTag] = [:]
        
        // Fetch tags in parallel
        await withTaskGroup(of: (String, SongTag?).self) { group in
            for songId in songIds {
                group.addTask {
                    let tag = await self.getTag(for: songId)
                    return (songId, tag)
                }
            }
            
            for await (songId, tag) in group {
                if let tag = tag {
                    tags[songId] = tag
                }
            }
        }
        
        return tags
    }
    
    /// Preload tags for a list of songs
    /// - Parameter songs: Array of songs to preload tags for
    func preloadTags(for songs: [Song]) async {
        let songIds = songs.map { $0.id }
        _ = await getTags(for: songIds)
    }
    
    // MARK: - Private Methods
    
    /// Fetch tag from Firestore
    private func fetchTagFromFirestore(songId: String) async throws -> SongTag? {
        let docRef = db.collection("songs").document(songId)
        let document = try await docRef.getDocument()
        
        guard document.exists,
              let data = document.data() else {
            return nil
        }
        
        // Convert Firestore data to SongTag
        let jsonData = try JSONSerialization.data(withJSONObject: data)
        let decoder = JSONDecoder()
        
        // Handle Firestore Timestamp conversion if needed
        let tag = try decoder.decode(SongTag.self, from: jsonData)
        return tag
    }
    
    /// Get generation count for a song (how many users have learned it)
    /// - Parameter songId: The song ID
    /// - Returns: Generation count if found, nil otherwise
    func getGenerationCount(for songId: String) async -> Int? {
        let docRef = db.collection("songs").document(songId)
        
        do {
            let document = try await docRef.getDocument()
            guard document.exists,
                  let data = document.data(),
                  let count = data["generation_count"] as? Int else {
                return nil
            }
            return count
        } catch {
            print("⚠️ [MusicSongTagService] Failed to fetch generation count for song \(songId): \(error)")
            return nil
        }
    }
    
    /// Clear all cached song tags
    func clearCache() {
        cachedTags.removeAll()
        print("✅ [MusicSongTagService] Cache cleared")
    }
}

