//
//  InputLanguage.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/9/25.
//

import Foundation

enum InputLanguage: String, CaseIterable {
    case auto = "auto"
    case english = "en"
    case french = "fr"
    case spanish = "es"
    case german = "de"
    case italian = "it"
    case portuguese = "pt"
    case russian = "ru"
    case croatian = "hr"
    case serbian = "sr"
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
    case filipino = "tl"
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
    
    var displayName: String {
        switch self {
        case .auto:
            return "Auto Detect"
        default:
            return Locale.current.localizedString(forLanguageCode: rawValue)?.capitalized ?? rawValue.uppercased()
        }
    }
    
    var isAuto: Bool {
        return self == .auto
    }
    
    var languageCode: String {
        return rawValue
    }
} 
