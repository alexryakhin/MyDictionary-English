//
//  EnglishAccent.swift
//  My Dictionary
//
//  Created by Alexander Riakhin on 8/9/25.
//

/**
 Google's various APIs, particularly the Cloud Text-to-Speech API and the Assistant SDK, support a range of English accents. These accents are typically identified by their respective locale codes.

 The supported English locales and their associated accents include:

 en-AU: (Australian English)
 en-CA: (Canadian English, often using en-US voices)
 en-GB: (British English)
 en-IN: (Indian English)
 en-US: (American English)
 en-BE: (Belgian English, often using en-GB voices)
 en-SG: (Singaporean English, often using en-GB voices)
 en-IE: (Irish English)
 en-ZA: (South African English)
 */

enum EnglishAccent: String, CaseIterable {
    case australian
    case canadian
    case british
    case indian
    case american
    case belgian
    case singaporean
    case irish
    case southAfrican

    var displayName: String {
        switch self {
        case .australian: return Loc.Tts.EnglishAccents.australian
        case .canadian: return Loc.Tts.EnglishAccents.canadian
        case .british: return Loc.Tts.EnglishAccents.british
        case .indian: return Loc.Tts.EnglishAccents.indian
        case .american: return Loc.Tts.EnglishAccents.american
        case .belgian: return Loc.Tts.EnglishAccents.belgian
        case .singaporean: return Loc.Tts.EnglishAccents.singaporean
        case .irish: return Loc.Tts.EnglishAccents.irish
        case .southAfrican: return Loc.Tts.EnglishAccents.southAfrican
        }
    }

    var localeCode: String {
        switch self {
        case .australian: "en-AU"
        case .canadian: "en-CA"
        case .british: "en-GB"
        case .indian: "en-IN"
        case .american: "en-US"
        case .belgian: "en-BE"
        case .singaporean: "en-SG"
        case .irish: "en-IE"
        case .southAfrican: "en-ZA"
        }
    }
}
