//
//  MusicRecommendationEngine.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin
//

import Foundation
import CoreData

/// On-device recommendation engine for music songs
/// Uses cached song tags and user profile from CoreData
final class MusicRecommendationEngine {
    
    static let shared = MusicRecommendationEngine()
    
    private let coreDataService = CoreDataService.shared
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// Recommend songs based on user profile and cached song tags
    /// - Parameters:
    ///   - top: Number of recommendations to return
    ///   - userProfile: User's profile with study languages
    ///   - availableSongs: List of available songs to filter from
    ///   - songTags: Cached song tags from Firestore
    /// - Returns: Array of recommended songs sorted by score
    func recommend(
        top: Int = 20,
        userProfile: UserOnboardingProfile,
        availableSongs: [Song],
        songTags: [String: SongTag]
    ) -> [Song] {
        guard let firstStudyLanguage = userProfile.studyLanguages.first else {
            return []
        }
        
        let userLevel = firstStudyLanguage.proficiencyLevel
        let userLevelInt = userLevel.level
        
        // Get user's liked items from CoreData
        let likedItems = getLikedItemsFromCoreData()
        let likedThemes = getLikedThemesFromCoreData()
        let userEmbedding = getUserEmbeddingFromCoreData()
        
        // Filter songs by CEFR compatibility
        let candidates = availableSongs.filter { song in
            guard let tag = songTags[song.id] else { return false }
            
            // Check if song's CEFR level is appropriate for user
            guard let tagLevel = CEFRLevel(rawValue: tag.cefr) else { return false }
            return tagLevel.level <= userLevelInt + 1 // Allow up to +1 level
        }
        
        // Score each candidate
        var scores: [Song: Double] = [:]
        
        for song in candidates {
            guard let tag = songTags[song.id] else { continue }
            
            let cefrMatch = calculateCEFRMatchScore(tag.cefr, userLevel: userLevel)
            let embeddingSim = calculateEmbeddingSimilarity(tag.embeddings, userEmbedding: userEmbedding)
            let themeOverlap = calculateThemeOverlap(tag.themes, userThemes: likedThemes)
            
            // Weighted scoring: 0.4*cefrMatch + 0.3*embeddingSim + 0.3*themeOverlap
            let score = 0.4 * cefrMatch + 0.3 * embeddingSim + 0.3 * themeOverlap
            
            scores[song] = score
        }
        
        // Sort by score and return top N
        return scores.sorted { $0.value > $1.value }
            .prefix(top)
            .map { $0.key }
    }
    
    // MARK: - Private Methods
    
    /// Calculate CEFR match score (0.0 to 1.0)
    private func calculateCEFRMatchScore(_ songCEFR: String, userLevel: CEFRLevel) -> Double {
        guard let songLevel = CEFRLevel(rawValue: songCEFR) else { return 0.0 }
        
        let levelDiff = abs(songLevel.level - userLevel.level)
        
        // Perfect match = 1.0, +1 level = 0.8, +2 levels = 0.5, etc.
        if levelDiff == 0 {
            return 1.0
        } else if levelDiff == 1 {
            return 0.8
        } else if levelDiff == 2 {
            return 0.5
        } else {
            return 0.2
        }
    }
    
    /// Calculate cosine similarity between song embedding and user embedding
    private func calculateEmbeddingSimilarity(_ songEmbedding: [Float], userEmbedding: [Float]) -> Double {
        guard !songEmbedding.isEmpty, !userEmbedding.isEmpty,
              songEmbedding.count == userEmbedding.count else {
            return 0.0
        }
        
        // Cosine similarity: dot product / (magnitude1 * magnitude2)
        var dotProduct: Float = 0.0
        var magnitude1: Float = 0.0
        var magnitude2: Float = 0.0
        
        for i in 0..<songEmbedding.count {
            dotProduct += songEmbedding[i] * userEmbedding[i]
            magnitude1 += songEmbedding[i] * songEmbedding[i]
            magnitude2 += userEmbedding[i] * userEmbedding[i]
        }
        
        magnitude1 = sqrt(magnitude1)
        magnitude2 = sqrt(magnitude2)
        
        guard magnitude1 > 0 && magnitude2 > 0 else { return 0.0 }
        
        let similarity = Double(dotProduct / (magnitude1 * magnitude2))
        // Normalize to 0.0-1.0 range (cosine similarity is -1 to 1)
        return max(0.0, (similarity + 1.0) / 2.0)
    }
    
    /// Calculate theme overlap score
    private func calculateThemeOverlap(_ songThemes: [String], userThemes: Set<String>) -> Double {
        guard !songThemes.isEmpty else { return 0.0 }
        
        let songThemeSet = Set(songThemes)
        let intersection = songThemeSet.intersection(userThemes)
        
        // Return ratio of overlapping themes
        return Double(intersection.count) / Double(max(songThemes.count, 1))
    }
    
    /// Get user's liked items from CoreData
    private func getLikedItemsFromCoreData() -> Set<String> {
        let context = coreDataService.context
        
        return context.performAndWait {
            let fetchRequest = CDMusicLike.fetchRequest()
            
            guard let likes = try? context.fetch(fetchRequest) else {
                return Set<String>()
            }
            
            return Set(likes.compactMap { $0.itemId })
        }
    }
    
    /// Get user's liked themes from CoreData (extracted from liked items)
    private func getLikedThemesFromCoreData() -> Set<String> {
        // For now, return empty set - can be enhanced to extract themes from liked items
        // This would require storing theme information with liked items
        return Set<String>()
    }
    
    /// Get user's embedding buffer from CoreData
    private func getUserEmbeddingFromCoreData() -> [Float] {
        // For now, return empty array - can be enhanced to store user embedding
        // This would require adding embedding storage to user profile
        return []
    }
}

