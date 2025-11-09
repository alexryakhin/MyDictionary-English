//
//  MusicDiscoveringResponse.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin
//

import Foundation
import OpenAI

// Note: AIComprehensionQuestion is defined in Shared/Services/AI/Models/AIStoryResponse.swift

struct MusicDiscoveringResponse: Codable, JSONSchemaConvertible {
    let songInfo: SongInfo
    let explanations: [LyricExplanation]
    let vocabularyWords: [VocabularyWord]
    let culturalContext: String?
    let quiz: AIMusicLessonQuiz
    
    enum CodingKeys: String, CodingKey {
        case songInfo
        case explanations
        case vocabularyWords
        case culturalContext
        case quiz
    }
    
    static let example: Self = {
        .init(
            songInfo: SongInfo.example,
            explanations: [LyricExplanation.example],
            vocabularyWords: [VocabularyWord.example],
            culturalContext: "This song explores themes of love and longing, common in Spanish ballads.",
            quiz: AIMusicLessonQuiz.example
        )
    }()
    
    init(
        songInfo: SongInfo,
        explanations: [LyricExplanation],
        vocabularyWords: [VocabularyWord],
        culturalContext: String?,
        quiz: AIMusicLessonQuiz
    ) {
        self.songInfo = songInfo
        self.explanations = explanations
        self.vocabularyWords = vocabularyWords
        self.culturalContext = culturalContext
        self.quiz = quiz
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.songInfo = try container.decode(SongInfo.self, forKey: .songInfo)
        self.explanations = try container.decode([LyricExplanation].self, forKey: .explanations)
        self.vocabularyWords = try container.decode([VocabularyWord].self, forKey: .vocabularyWords)
        self.culturalContext = try container.decodeIfPresent(String.self, forKey: .culturalContext)
        self.quiz = try container.decodeIfPresent(AIMusicLessonQuiz.self, forKey: .quiz) ?? AIMusicLessonQuiz.empty
    }
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
    let phonetics: String
    let examples: [String]
    let partOfSpeech: PartOfSpeech
    let context: String?
    
    static let example: Self = {
        .init(
            word: "carnaval",
            definition: "A festival or celebration, especially one held before Lent",
            phonetics: "/kaɾˈnal/",
            examples: [
                "El carnaval de Río es famoso en todo el mundo.",
                "Durante el carnaval, las calles se llenan de música y color."
            ],
            partOfSpeech: .noun,
            context: "La vida es un carnaval"
        )
    }()
}

struct AIMusicLessonQuiz: Codable, JSONSchemaConvertible {
    let multipleChoice: [AIComprehensionQuestion]
    let fillInBlanks: [AIMusicFillInBlankQuestion]
    let difficulty: String?
    
    var hasRequiredContent: Bool {
        !multipleChoice.isEmpty && !fillInBlanks.isEmpty
    }
    
    static let example: Self = {
        .init(
            multipleChoice: [AIComprehensionQuestion.example],
            fillInBlanks: [AIMusicFillInBlankQuestion.example],
            difficulty: "B1"
        )
    }()
    
    static var empty: Self {
        .init(multipleChoice: [], fillInBlanks: [], difficulty: nil)
    }
}

struct AIMusicFillInBlankQuestion: Codable, JSONSchemaConvertible {
    let prompt: String
    let correctAnswer: String
    let options: [String]
    let explanation: String
    let lyricReference: String
    
    static let example: Self = {
        .init(
            prompt: "Completa la frase: La vida es un _ lleno de sorpresas.",
            correctAnswer: "carnaval",
            options: ["carnaval", "desierto", "invierno", "tiempo"],
            explanation: "La expresión 'La vida es un carnaval' es central en la canción.",
            lyricReference: "La vida es un carnaval"
        )
    }()
}

