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

    struct LyricExplanation: Codable, JSONSchemaConvertible {
        let lyricLine: String
        let explanation: String
        let lineNumber: Int

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

    struct GrammarNugget: Codable, JSONSchemaConvertible {
        let rule: String
        let example: String
        let explanation: String
        let cefr: CEFRLevel

        static let example: Self = {
            .init(
                rule: "Subject-verb agreement",
                example: "El perro corre; ella corre.",
                explanation: "In Spanish, the subject and verb must agree in number. 'El perro' is singular, so 'corre' is also singular.",
                cefr: .a1
            )
        }()
    }

    let explanations: [LyricExplanation]
    let vocabularyWords: [VocabularyWord]
    let grammarNuggets: [GrammarNugget]
    let culturalContext: String
    let comprehensionQuestions: [AIComprehensionQuestion]

    static let example: Self = {
        .init(
            explanations: [LyricExplanation.example],
            vocabularyWords: [VocabularyWord.example],
            grammarNuggets: [GrammarNugget.example],
            culturalContext: "This song explores themes of love and longing, common in Spanish ballads.",
            comprehensionQuestions: [AIComprehensionQuestion.example]
        )
    }()
}
