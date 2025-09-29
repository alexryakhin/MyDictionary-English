//
//  SpanishAccent.swift
//  My Dictionary
//
//  Created by Alexander Riakhin on 29/9/25.
//

/**
 Google's various APIs, particularly the Cloud Text-to-Speech API and the Assistant SDK, support a range of Spanish accents. These accents are typically identified by their respective locale codes.

 The supported Spanish locales and their associated accents include:

 •    es-ES → Castilian Spanish (Spain)
 •    es-MX → Mexican Spanish
 •    es-US → US Spanish (Latino accent, common in the US)
 •    es-CO → Colombian Spanish
 •    es-AR → Argentine Spanish
 •    es-CL → Chilean Spanish
 */

enum SpanishAccent: String, CaseIterable {
    case castilian
    case mexican
    case unitedStates
    case colombian
    case argentine
    case chileno

    var displayName: String {
        switch self {
        case .castilian: return Loc.Tts.SpanishAccents.castilian
        case .mexican: return Loc.Tts.SpanishAccents.mexican
        case .unitedStates: return Loc.Tts.SpanishAccents.unitedStates
        case .colombian: return Loc.Tts.SpanishAccents.colombian
        case .argentine: return Loc.Tts.SpanishAccents.argentine
        case .chileno: return Loc.Tts.SpanishAccents.chileno
        }
    }

    var localeCode: String {
        switch self {
        case .castilian: return "es-ES"
        case .mexican: return "es-MX"
        case .unitedStates: return "es-US"
        case .colombian: return "es-CO"
        case .argentine: return "es-AR"
        case .chileno: return "es-CL"
        }
    }
}
