//
//  FirestoreLesson.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin
//

import Foundation
import FirebaseFirestore

/// Public/shared lesson content stored in Firestore
/// CEFR-agnostic core content, personalized on-device
struct FirestoreLesson: Codable {
    let songId: String
    let language: InputLanguage
    let phrases: [LessonPhrase]
    let grammarNuggets: [GrammarNugget]
    let explanations: [LyricExplanation]
    let cultureNotes: String
    let quizTemplate: QuizTemplate
    let generatedBy: String
    let generatedAt: Date
    let version: Int
    
    enum CodingKeys: String, CodingKey {
        case songId = "song_id"
        case language
        case phrases
        case grammarNuggets = "grammar_nuggets"
        case explanations
        case cultureNotes = "culture_notes"
        case quizTemplate = "quiz_template"
        case generatedBy = "generated_by"
        case generatedAt = "generated_at"
        case version
    }

    init(
        songId: String,
        language: InputLanguage,
        phrases: [LessonPhrase],
        grammarNuggets: [GrammarNugget],
        explanations: [LyricExplanation],
        cultureNotes: String,
        quizTemplate: QuizTemplate,
        generatedBy: String,
        generatedAt: Date,
        version: Int
    ) {
        self.songId = songId
        self.language = language
        self.phrases = phrases
        self.grammarNuggets = grammarNuggets
        self.explanations = explanations
        self.cultureNotes = cultureNotes
        self.quizTemplate = quizTemplate
        self.generatedBy = generatedBy
        self.generatedAt = generatedAt
        self.version = version
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        songId = try container.decode(String.self, forKey: .songId)
        language = try container.decode(InputLanguage.self, forKey: .language)
        phrases = try container.decode([LessonPhrase].self, forKey: .phrases)
        grammarNuggets = try container.decode([GrammarNugget].self, forKey: .grammarNuggets)
        explanations = try container.decode([LyricExplanation].self, forKey: .explanations)
        cultureNotes = try container.decode(String.self, forKey: .cultureNotes)
        quizTemplate = try container.decode(QuizTemplate.self, forKey: .quizTemplate)
        generatedBy = try container.decode(String.self, forKey: .generatedBy)

        // Handle Firestore Timestamp
        if let timestamp = try? container.decode(Timestamp.self, forKey: .generatedAt) {
            generatedAt = timestamp.dateValue()
        } else if let date = try? container.decode(Date.self, forKey: .generatedAt) {
            generatedAt = date
        } else {
            generatedAt = Date()
        }

        version = try container.decode(Int.self, forKey: .version)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(songId, forKey: .songId)
        try container.encode(language, forKey: .language)
        try container.encode(phrases, forKey: .phrases)
        try container.encode(grammarNuggets, forKey: .grammarNuggets)
        try container.encode(explanations, forKey: .explanations)
        try container.encode(cultureNotes, forKey: .cultureNotes)
        try container.encode(quizTemplate, forKey: .quizTemplate)
        try container.encode(generatedBy, forKey: .generatedBy)
        try container.encode(Timestamp(date: generatedAt), forKey: .generatedAt)
        try container.encode(version, forKey: .version)
    }
}

/// Phrase with CEFR tag for on-device filtering
struct LessonPhrase: Codable, Hashable {
    let text: String
    let meaning: String
    let phonetics: String
    let cefr: CEFRLevel
    let example: String
    let partOfSpeech: PartOfSpeech

    enum CodingKeys: String, CodingKey {
        case text
        case meaning
        case phonetics
        case cefr
        case example
        case partOfSpeech = "part_of_speech"
    }
}

struct LyricExplanation: Codable, Hashable, Comparable {
    static func < (lhs: LyricExplanation, rhs: LyricExplanation) -> Bool {
        lhs.lyricLine < rhs.lyricLine
    }

    let lyricLine: String
    let explanation: String
    let lineNumber: Int
}

/// Grammar rule with CEFR tag
struct GrammarNugget: Codable, Hashable {
    let rule: String
    let example: String
    let explanation: String
    let cefr: CEFRLevel
}

/// Quiz template for generating quizzes on-device
struct QuizTemplate: Codable {
    let fillInBlanks: [FillInBlankItem]
    let meaningMCQ: [MCQItem]
    
    enum CodingKeys: String, CodingKey {
        case fillInBlanks = "fill_in_blanks"
        case meaningMCQ = "meaning_mcq"
    }
}

struct FillInBlankItem: Codable, Hashable {
    let lyricReference: String
    let blankWord: String
    let options: [String]

    enum CodingKeys: String, CodingKey {
        case lyricReference = "lyric_reference"
        case blankWord = "blank_word"
        case options
    }
}

struct MCQItem: Codable, Hashable {
    let question: String
    let correctAnswer: String
    let options: [String]
    let explanation: String?
    
    enum CodingKeys: String, CodingKey {
        case question
        case correctAnswer = "correct_answer"
        case options
        case explanation
    }
}

