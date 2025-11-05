//
//  SongTag.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin
//

import Foundation

/// Public/shared song tag metadata for recommendations
/// Stored in Firestore, accessible to all users
struct SongTag: Codable {
    let id: String
    let cefr: String // CEFR level (A1, A2, B1, etc.)
    let vocabCEFR: [String: String] // word → CEFR level mapping
    let grammarPoints: [String] // e.g. ["presente continuo", "imperativo"]
    let themes: [String] // e.g. ["love", "nostalgia"]
    let embeddings: [Float] // 384-dim embedding vector
    let difficultyScore: Double // 0.0 to 1.0
    
    enum CodingKeys: String, CodingKey {
        case id
        case cefr
        case vocabCEFR = "vocab_cefr"
        case grammarPoints = "grammar_points"
        case themes
        case embeddings
        case difficultyScore = "difficulty_score"
    }
}

