//
//  InputLanguage.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/9/25.
//

import Foundation

enum InputLanguage: String, Codable, CaseIterable {
    case auto = "auto"
    case english = "en"
    case french = "fr"
    case spanish = "es"
    case german = "de"
    case italian = "it"
    case portuguese = "pt"
    case russian = "ru"
    case croatian = "hr"
    case japanese = "ja"
    case korean = "ko"
    case chinese = "zh"
    case arabic = "ar"
    case hindi = "hi"
    case dutch = "nl"
    case swedish = "sv"
    case norwegian = "no"
    case danish = "da"
    case finnish = "fi"
    case polish = "pl"
    case turkish = "tr"
    case greek = "el"
    case hebrew = "he"
    case thai = "th"
    case vietnamese = "vi"
    case indonesian = "id"
    case malay = "ms"
    case urdu = "ur"
    case persian = "fa"
    case bengali = "bn"
    case tamil = "ta"
    case telugu = "te"
    case marathi = "mr"
    case gujarati = "gu"
    case kannada = "kn"
    case malayalam = "ml"
    case punjabi = "pa"
    case amharic = "am"
    case armenian = "hy"
    case bulgarian = "bg"
    case burmese = "my"
    case catalan = "ca"
    case cherokee = "chr"
    case czech = "cs"
    case georgian = "ka"
    case hungarian = "hu"
    case icelandic = "is"
    case khmer = "km"
    case lao = "lo"
    case mongolian = "mn"
    case oriya = "or"
    case romanian = "ro"
    case sinhalese = "si"
    case slovak = "sk"
    case tibetan = "bo"
    case ukrainian = "uk"
    case kazakh = "kk"
    
    var displayName: String {
        switch self {
        case .auto:
            return Loc.Words.InputLanguage.autoDetect
        default:
            return Locale.current.localizedString(forLanguageCode: rawValue)?.capitalized ?? rawValue.uppercased()
        }
    }

    var englishName: String {
        switch self {
        case .auto:
            return "Auto-detected language"
        default:
            return Locale(identifier: "en_US").localizedString(forLanguageCode: rawValue)?.capitalized ?? rawValue.uppercased()
        }
    }

    var isAuto: Bool {
        return self == .auto
    }
    
    var languageCode: String {
        return rawValue
    }

    static var casesWithoutAuto: [InputLanguage] {
        Self.allCases.filter { $0 != .auto }.sorted { $0.displayName < $1.displayName }
    }
}
