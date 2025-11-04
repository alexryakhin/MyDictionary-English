//
//  CountryRegion.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 1/10/25.
//

import Foundation

/**
 Represents country/region codes used for building locale codes for TTS services.

 The region code is combined with a language code to create a full locale (e.g., "en-US", "es-MX").
 Google TTS and other services automatically handle whether a specific combination is supported,
 falling back to the base language if needed.

 Supported combinations include:
 - English: US, GB, AU, CA, IN, IE, ZA, SG, BE, NZ
 - Spanish: ES, MX, US, CO, AR, CL
 - French: FR, CA, BE, CH
 - German: DE, AT, CH
 - Portuguese: BR, PT
 - Italian: IT, CH
 - And many more...
 */
enum CountryRegion: String, CaseIterable, Codable {
    // Americas
    case unitedStates = "US"
    case canada = "CA"
    case mexico = "MX"
    case argentina = "AR"
    case brazil = "BR"
    case chile = "CL"
    case colombia = "CO"

    // Europe
    case unitedKingdom = "GB"
    case ireland = "IE"
    case spain = "ES"
    case france = "FR"
    case germany = "DE"
    case italy = "IT"
    case portugal = "PT"
    case netherlands = "NL"
    case belgium = "BE"
    case switzerland = "CH"
    case austria = "AT"
    case poland = "PL"
    case sweden = "SE"
    case denmark = "DK"
    case norway = "NO"
    case finland = "FI"
    case greece = "GR"
    case czechRepublic = "CZ"
    case romania = "RO"
    case hungary = "HU"
    case slovakia = "SK"
    case croatia = "HR"

    // Asia Pacific
    case australia = "AU"
    case newZealand = "NZ"
    case india = "IN"
    case singapore = "SG"
    case japan = "JP"
    case china = "CN"
    case hongKong = "HK"
    case taiwan = "TW"
    case korea = "KR"
    case thailand = "TH"
    case vietnam = "VN"
    case indonesia = "ID"
    case malaysia = "MY"
    case philippines = "PH"

    // Middle East & Africa
    case southAfrica = "ZA"
    case israel = "IL"
    case turkey = "TR"
    case egypt = "EG"
    case saudiArabia = "SA"
    case uae = "AE"

    static var allCasesSorted: [CountryRegion] {
        Self.allCases.sorted { $0.displayName < $1.displayName }
    }

    var displayName: String {
        // Use Locale to get localized country names
        let locale = Locale.current
        return locale.localizedString(forRegionCode: rawValue) ?? rawValue
    }

    var flagEmoji: String {
        switch self {
            // Americas
        case .unitedStates: return "🇺🇸"
        case .canada: return "🇨🇦"
        case .mexico: return "🇲🇽"
        case .argentina: return "🇦🇷"
        case .brazil: return "🇧🇷"
        case .chile: return "🇨🇱"
        case .colombia: return "🇨🇴"

            // Europe
        case .unitedKingdom: return "🇬🇧"
        case .ireland: return "🇮🇪"
        case .spain: return "🇪🇸"
        case .france: return "🇫🇷"
        case .germany: return "🇩🇪"
        case .italy: return "🇮🇹"
        case .portugal: return "🇵🇹"
        case .netherlands: return "🇳🇱"
        case .belgium: return "🇧🇪"
        case .switzerland: return "🇨🇭"
        case .austria: return "🇦🇹"
        case .poland: return "🇵🇱"
        case .sweden: return "🇸🇪"
        case .denmark: return "🇩🇰"
        case .norway: return "🇳🇴"
        case .finland: return "🇫🇮"
        case .greece: return "🇬🇷"
        case .czechRepublic: return "🇨🇿"
        case .romania: return "🇷🇴"
        case .hungary: return "🇭🇺"
        case .slovakia: return "🇸🇰"
        case .croatia: return "🇭🇷"

            // Asia Pacific
        case .australia: return "🇦🇺"
        case .newZealand: return "🇳🇿"
        case .india: return "🇮🇳"
        case .singapore: return "🇸🇬"
        case .japan: return "🇯🇵"
        case .china: return "🇨🇳"
        case .hongKong: return "🇭🇰"
        case .taiwan: return "🇹🇼"
        case .korea: return "🇰🇷"
        case .thailand: return "🇹🇭"
        case .vietnam: return "🇻🇳"
        case .indonesia: return "🇮🇩"
        case .malaysia: return "🇲🇾"
        case .philippines: return "🇵🇭"

            // Middle East & Africa
        case .southAfrica: return "🇿🇦"
        case .israel: return "🇮🇱"
        case .turkey: return "🇹🇷"
        case .egypt: return "🇪🇬"
        case .saudiArabia: return "🇸🇦"
        case .uae: return "🇦🇪"
        }
    }

    /// Builds a full locale code by combining language and region (e.g., "en-US", "es-MX")
    func localeCode(for languageCode: String) -> String {
        return "\(languageCode)-\(rawValue)"
    }

    /// Returns popular regions for a given language
    static func popularRegions(for languageCode: String) -> [CountryRegion] {
        switch languageCode.lowercased() {
        case "en":
            return [.unitedStates, .unitedKingdom, .australia, .canada, .india, .ireland, .southAfrica]
        case "es":
            return [.spain, .mexico, .argentina, .colombia, .chile, .unitedStates]
        case "fr":
            return [.france, .canada, .belgium, .switzerland]
        case "de":
            return [.germany, .austria, .switzerland]
        case "pt":
            return [.brazil, .portugal]
        case "it":
            return [.italy, .switzerland]
        case "nl":
            return [.netherlands, .belgium]
        case "pl":
            return [.poland]
        case "sv":
            return [.sweden]
        case "da":
            return [.denmark]
        case "no":
            return [.norway]
        case "fi":
            return [.finland]
        case "el":
            return [.greece]
        case "cs":
            return [.czechRepublic]
        case "ro":
            return [.romania]
        case "hu":
            return [.hungary]
        case "sk":
            return [.slovakia]
        case "hr":
            return [.croatia]
        case "ja":
            return [.japan]
        case "zh":
            return [.china, .taiwan, .hongKong]
        case "ko":
            return [.korea]
        case "th":
            return [.thailand]
        case "vi":
            return [.vietnam]
        case "id":
            return [.indonesia]
        case "ms":
            return [.malaysia]
        case "tr":
            return [.turkey]
        case "ar":
            return [.saudiArabia, .egypt, .uae]
        case "he":
            return [.israel]
        default:
            return [.unitedStates] // Default fallback
        }
    }
}

