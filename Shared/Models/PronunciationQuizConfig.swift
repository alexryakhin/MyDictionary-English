//
//  PronunciationQuizConfig.swift
//  My Dictionary
//
//  Created by Alexander Riakhin on 11/14/25.
//
import Foundation

struct PronunciationQuizConfig {
    struct Item: Hashable {
        let index: Int
        let text: String
        let language: InputLanguage
    }

    struct SubmissionItem: Hashable {
        let item: Item
        let spokenText: String
        let isCorrect: Bool
    }

    let items: [Item]
    let onAnswer: (SubmissionItem) -> Void
    let onCompletion: ([SubmissionItem]) -> Void
}
