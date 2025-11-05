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
    let artists: [AIRecommendationItem]
    let albums: [AIRecommendationItem]
    let songs: [AIRecommendationItem]
    
    static let example: Self = {
        .init(
            artists: [
                AIRecommendationItem(
                    title: "Billie Eilish",
                    artist: "Billie Eilish",
                    language: "en",
                    reason: "Popular artist with clear pronunciation and modern English"
                )
            ],
            albums: [
                AIRecommendationItem(
                    title: "Happier Than Ever",
                    artist: "Billie Eilish",
                    language: "en",
                    reason: "Great album for learning contemporary English"
                )
            ],
            songs: [
                AIRecommendationItem(
                    title: "Bad Guy",
                    artist: "Billie Eilish",
                    language: "en",
                    reason: "Clear pronunciation and repetitive lyrics"
                )
            ]
        )
    }()
}

/// AI recommendation item (artist, album, or song)
/// OpenAI only provides names and reasons - no IDs or URLs
struct AIRecommendationItem: Codable, JSONSchemaConvertible {
    let title: String // Artist name, album name, or song title
    let artist: String // Artist name (required for albums and songs)
    let language: String
    let reason: String
    
    static let example: Self = {
        .init(
            title: "Despacito",
            artist: "Luis Fonsi",
            language: "es",
            reason: "Popular Spanish song with clear pronunciation"
        )
    }()
}

