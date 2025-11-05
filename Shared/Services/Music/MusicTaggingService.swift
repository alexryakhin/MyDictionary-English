//
//  MusicTaggingService.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin
//

import Foundation
import FirebaseFirestore
import OpenAI

/// Service for tagging songs with AI-generated metadata
/// Tags are stored in Firestore for public access
final class MusicTaggingService {
    
    static let shared = MusicTaggingService()
    
    private let db = Firestore.firestore()
    private let aiService = AIService.shared
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// Tag a single song with AI-generated metadata
    /// - Parameters:
    ///   - song: The song to tag
    ///   - lyrics: The song lyrics
    /// - Returns: SongTag with CEFR, themes, grammar points, embedding
    func tagSong(_ song: Song, lyrics: String) async throws -> SongTag {
        guard aiService.canMakeAIRequest() else {
            throw AIError.proRequired
        }
        
        // 1. Generate embedding using OpenAI
        let embedding = try await generateEmbedding(for: lyrics)
        
        // 2. Analyze lyrics for CEFR, themes, grammar points
        let analysis = try await analyzeLyrics(song: song, lyrics: lyrics)
        
        // 3. Create SongTag
        let tag = SongTag(
            id: song.id,
            cefr: analysis.cefr,
            vocabCEFR: analysis.vocabCEFR,
            grammarPoints: analysis.grammarPoints,
            themes: analysis.themes,
            embeddings: embedding,
            difficultyScore: analysis.difficultyScore
        )
        
        // 4. Save to Firestore
        try await saveTagToFirestore(tag, for: song.id)
        
        return tag
    }
    
    /// Load song tag from Firestore
    /// - Parameter songId: The song ID
    /// - Returns: SongTag if found, nil otherwise
    func getTagFromFirestore(songId: String) async throws -> SongTag? {
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
    
    // MARK: - Private Methods
    
    /// Generate embedding for lyrics using OpenAI
    private func generateEmbedding(for lyrics: String) async throws -> [Float] {
        // Use OpenAI embeddings API
        // Note: This requires OpenAI SDK with embeddings support
        // For now, return empty array - will be implemented with proper OpenAI embeddings API
        
        // TODO: Implement OpenAI embeddings API call
        // This would use: openai.embeddings.create(model: "text-embedding-3-small", input: lyrics)
        
        // Placeholder: return empty array
        // In production, this should call OpenAI embeddings API
        return []
    }
    
    /// Analyze lyrics for CEFR level, themes, grammar points
    private func analyzeLyrics(song: Song, lyrics: String) async throws -> LyricsAnalysis {
        // Create AI prompt for lyrics analysis
        let prompt = """
        Analyze this song for language learning purposes:
        
        Song: "\(song.title)" by \(song.artist)
        Lyrics:
        \(lyrics)
        
        Return JSON with:
        - cefr_level: CEFR level (A1, A2, B1, B2, C1, C2)
        - vocab_cefr: Dictionary mapping words to CEFR levels
        - grammar_points: Array of grammar points found (e.g. ["presente continuo", "imperativo"])
        - themes: Array of themes (e.g. ["love", "nostalgia"])
        - difficulty_score: Double from 0.0 to 1.0
        """
        
        // Use AI service to analyze (this would require a new AI request type)
        // For now, return placeholder
        // TODO: Implement proper AI analysis request
        
        return LyricsAnalysis(
            cefr: "B1",
            vocabCEFR: [:],
            grammarPoints: [],
            themes: [],
            difficultyScore: 0.5
        )
    }
    
    /// Save tag to Firestore
    private func saveTagToFirestore(_ tag: SongTag, for songId: String) async throws {
        let docRef = db.collection("songs").document(songId)
        
        // Convert to Firestore-compatible dictionary
        let encoder = JSONEncoder()
        let data = try encoder.encode(tag)
        let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
        
        try await docRef.setData(dict, merge: true)
    }
}

// MARK: - Supporting Types

struct LyricsAnalysis {
    let cefr: String
    let vocabCEFR: [String: String]
    let grammarPoints: [String]
    let themes: [String]
    let difficultyScore: Double
}

