//
//  LanguageDetector.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/9/25.
//

import Foundation
import NaturalLanguage

final class LanguageDetector {
    
    static let shared = LanguageDetector()
    
    private init() {}
    
    func detectLanguage(for text: String) -> InputLanguage {
        let languageRecognizer = NLLanguageRecognizer()
        languageRecognizer.processString(text)
        
        guard let language = languageRecognizer.dominantLanguage else {
            return .english
        }
        
        // Map NLLanguage to InputLanguage
        switch language {
        case .english:
            return .english
        case .french:
            return .french
        case .spanish:
            return .spanish
        case .german:
            return .german
        case .italian:
            return .italian
        case .portuguese:
            return .portuguese
        case .russian:
            return .russian
        case .japanese:
            return .japanese
        case .korean:
            return .korean
        case .simplifiedChinese, .traditionalChinese:
            return .chinese
        case .arabic:
            return .arabic
        case .hindi:
            return .hindi
        case .dutch:
            return .dutch
        case .swedish:
            return .swedish
        case .norwegian:
            return .norwegian
        case .danish:
            return .danish
        case .finnish:
            return .finnish
        case .polish:
            return .polish
        case .turkish:
            return .turkish
        case .greek:
            return .greek
        case .hebrew:
            return .hebrew
        case .thai:
            return .thai
        case .vietnamese:
            return .vietnamese
        case .indonesian:
            return .indonesian
        case .malay:
            return .malay
        case .urdu:
            return .urdu
        case .persian:
            return .persian
        case .bengali:
            return .bengali
        case .tamil:
            return .tamil
        case .telugu:
            return .telugu
        case .marathi:
            return .marathi
        case .gujarati:
            return .gujarati
        case .kannada:
            return .kannada
        case .malayalam:
            return .malayalam
        case .punjabi:
            return .punjabi
        case .croatian:
            return .croatian
        default:
            return .english
        }
    }
}
