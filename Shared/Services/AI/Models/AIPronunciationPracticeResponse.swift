//
//  AIPronunciationPracticeResponse.swift
//  My Dictionary
//
//  Created by GPT-5 Codex
//

import Foundation
import OpenAI

struct AIPronunciationPracticeResponse: Codable, JSONSchemaConvertible {
    let items: [Item]

    static let example: Self = {
        .init(items: [Item.example])
    }()

    struct Item: Codable, JSONSchemaConvertible {
        let word: String
        let language: InputLanguage
        let sentence: String

        static let example: Self = {
            .init(
                word: "perspective",
                language: .english,
                sentence: "The perspective of the protagonist is crucial to understanding the story."
            )
        }()
    }
}
