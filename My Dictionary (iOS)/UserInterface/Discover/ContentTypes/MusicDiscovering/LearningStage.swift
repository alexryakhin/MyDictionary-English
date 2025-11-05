//
//  LearningStage.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin
//

import Foundation

/// 5-stage learning loop for music-based language learning
enum LearningStage: String, CaseIterable, Identifiable {
    case preListen = "Pre-Listen"
    case listenRead = "Listen & Read"
    case deepDive = "Deep Dive"
    case practice = "Practice"
    case quiz = "Quiz & Review"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .preListen:
            return "eye"
        case .listenRead:
            return "headphones"
        case .deepDive:
            return "book"
        case .practice:
            return "mic"
        case .quiz:
            return "questionmark.circle"
        }
    }
    
    var description: String {
        switch self {
        case .preListen:
            return "Prepare for the song with key phrases"
        case .listenRead:
            return "Listen and read along with tap-to-translate"
        case .deepDive:
            return "Explore phrases, grammar, and culture"
        case .practice:
            return "Practice with shadowing, fill-in, or karaoke"
        case .quiz:
            return "Test your understanding"
        }
    }
    
    var index: Int {
        switch self {
        case .preListen: return 0
        case .listenRead: return 1
        case .deepDive: return 2
        case .practice: return 3
        case .quiz: return 4
        }
    }
}

