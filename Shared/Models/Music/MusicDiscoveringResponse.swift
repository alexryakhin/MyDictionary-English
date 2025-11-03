//
//  MusicDiscoveringResponse.swift
//  My Dictionary
//
//  Created by AI Assistant
//

import Foundation
import OpenAI

// Note: AIComprehensionQuestion is defined in Shared/Services/AI/Models/AIStoryResponse.swift

struct MusicDiscoveringResponse: Codable, JSONSchemaConvertible {
    let songInfo: SongInfo
    let explanations: [LyricExplanation]
    let vocabularyWords: [VocabularyWord]
    let culturalContext: String?
    let quiz: AIComprehensionQuiz?
    
    static let example: Self = {
        .init(
            songInfo: SongInfo.example,
            explanations: [LyricExplanation.example],
            vocabularyWords: [VocabularyWord.example],
            culturalContext: "This song explores themes of love and longing, common in Spanish ballads.",
            quiz: AIComprehensionQuiz.example
        )
    }()
}

struct SongInfo: Codable, JSONSchemaConvertible {
    let title: String
    let artist: String
    let album: String?
    let language: String
    
    static let example: Self = {
        .init(
            title: "La Vida Es Un Carnaval",
            artist: "Celia Cruz",
            album: "Mi Vida Es Cantar",
            language: "Spanish"
        )
    }()
}

struct LyricExplanation: Codable, JSONSchemaConvertible {
    let lyricLine: String
    let explanation: String
    let lineNumber: Int?
    
    static let example: Self = {
        .init(
            lyricLine: "La vida es un carnaval",
            explanation: "Life is a carnival - This phrase suggests that life should be celebrated like a carnival, with joy and festivity despite hardships.",
            lineNumber: 1
        )
    }()
}

struct VocabularyWord: Codable, JSONSchemaConvertible {
    let word: String
    let definition: String
    let examples: [String]
    let partOfSpeech: String
    let context: String?
    
    static let example: Self = {
        .init(
            word: "carnaval",
            definition: "A festival or celebration, especially one held before Lent",
            examples: [
                "El carnaval de Río es famoso en todo el mundo.",
                "Durante el carnaval, las calles se llenan de música y color."
            ],
            partOfSpeech: "noun",
            context: "La vida es un carnaval"
        )
    }()
}

struct AIComprehensionQuiz: Codable, JSONSchemaConvertible {
    let questions: [AIComprehensionQuestion]
    let difficulty: String?
    
    static let example: Self = {
        .init(
            questions: [AIComprehensionQuestion.example],
            difficulty: "B1"
        )
    }()
}

