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
        case .australian: "Australian"
        case .canadian: "Canadian"
        case .british: "British"
        case .indian: "Indian"
        case .american: "American"
        case .belgian: "Belgian"
        case .singaporean: "Singaporean"
        case .irish: "Irish"
        case .southAfrican: "South African"
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
