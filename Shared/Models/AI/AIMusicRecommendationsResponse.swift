//
//  AIMusicRecommendationsResponse.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin
//

import Foundation
import OpenAI

/// AI-generated music recommendations response
struct AIMusicRecommendationsResponse: Codable, JSONSchemaConvertible {
    let songs: [AIRecommendationSong]

    static let example: Self = {
        .init(
            songs: [
                AIRecommendationSong(
                    title: "Bad Guy",
                    artist: "Billie Eilish",
                    language: .english,
                    cefrLevel: .a2,
                    reason: "Clear pronunciation and repetitive lyrics"
                )
            ]
        )
    }()
}

/// AI recommendation item (song only)
/// OpenAI only provides names and reasons - no IDs or URLs
struct AIRecommendationSong: Codable, JSONSchemaConvertible {
    let title: String // Song title
    let artist: String // Artist name
    let language: InputLanguage
    let cefrLevel: CEFRLevel
    let reason: String
    
    static let example: Self = {
        .init(
            title: "Despacito",
            artist: "Luis Fonsi",
            language: .spanish,
            cefrLevel: .b1,
            reason: "Popular Spanish song with clear pronunciation"
        )
    }()
}

