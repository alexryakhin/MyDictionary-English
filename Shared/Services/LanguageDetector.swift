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
        
        // For single words, also check the confidence scores
        let hypotheses = languageRecognizer.languageHypotheses(withMaximum: 3)
        
        guard let language = languageRecognizer.dominantLanguage else {
            return .english
        }
        
        // For single words, if confidence is low, try to use character-based detection as fallback
        let isSingleWord = text.trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: .whitespaces)
            .count == 1
        
        if isSingleWord {
            let dominantConfidence = hypotheses[language] ?? 0.0
            
            // For Cyrillic languages, if confidence is low or if it's a close call between Cyrillic languages, use enhanced detection
            let isCyrillicLanguage = [NLLanguage.russian, .bulgarian, .ukrainian, .kazakh].contains(where: { $0.rawValue == language.rawValue })

            if dominantConfidence < 0.5 || (isCyrillicLanguage && dominantConfidence < 0.7) {
                if let characterBasedLanguage = detectLanguageByCharacters(text) {
                    return characterBasedLanguage
                }
            }
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
        case .amharic:
            return .amharic
        case .armenian:
            return .armenian
        case .bulgarian:
            return .bulgarian
        case .burmese:
            return .burmese
        case .catalan:
            return .catalan
        case .cherokee:
            return .cherokee
        case .czech:
            return .czech
        case .georgian:
            return .georgian
        case .hungarian:
            return .hungarian
        case .icelandic:
            return .icelandic
        case .khmer:
            return .khmer
        case .lao:
            return .lao
        case .mongolian:
            return .mongolian
        case .oriya:
            return .oriya
        case .romanian:
            return .romanian
        case .sinhalese:
            return .sinhalese
        case .slovak:
            return .slovak
        case .tibetan:
            return .tibetan
        case .ukrainian:
            return .ukrainian
        case .kazakh:
            return .kazakh
        default:
            return .english
        }
    }
    
    private func detectLanguageByCharacters(_ text: String) -> InputLanguage? {
        // Character-based language detection for single words
        let text = text.lowercased()
        
        // Check for Cyrillic characters (Russian, Bulgarian, Serbian, Ukrainian, etc.)
        let cyrillicPattern = "[а-яё]"
        if text.range(of: cyrillicPattern, options: .regularExpression) != nil {
            // Try to distinguish between Cyrillic languages based on character frequency
            return detectCyrillicLanguage(text)
        }
        
        // Check for Arabic characters
        let arabicPattern = "[ا-ي]"
        if text.range(of: arabicPattern, options: .regularExpression) != nil {
            return .arabic
        }
        
        // Check for Chinese characters (simplified and traditional)
        let chinesePattern = "[\\u4e00-\\u9fff]"
        if text.range(of: chinesePattern, options: .regularExpression) != nil {
            return .chinese
        }
        
        // Check for Japanese characters (Hiragana, Katakana, Kanji)
        let japanesePattern = "[\\u3040-\\u309f\\u30a0-\\u30ff\\u4e00-\\u9faf]"
        if text.range(of: japanesePattern, options: .regularExpression) != nil {
            return .japanese
        }
        
        // Check for Korean characters
        let koreanPattern = "[\\uac00-\\ud7af\\u1100-\\u11ff\\u3130-\\u318f]"
        if text.range(of: koreanPattern, options: .regularExpression) != nil {
            return .korean
        }
        
        // Check for Greek characters
        let greekPattern = "[\\u0370-\\u03ff]"
        if text.range(of: greekPattern, options: .regularExpression) != nil {
            return .greek
        }
        
        // Check for Hebrew characters
        let hebrewPattern = "[\\u0590-\\u05ff]"
        if text.range(of: hebrewPattern, options: .regularExpression) != nil {
            return .hebrew
        }
        
        // Check for Thai characters
        let thaiPattern = "[\\u0e00-\\u0e7f]"
        if text.range(of: thaiPattern, options: .regularExpression) != nil {
            return .thai
        }
        
        // Check for Devanagari characters (Hindi, Sanskrit, etc.)
        let devanagariPattern = "[\\u0900-\\u097f]"
        if text.range(of: devanagariPattern, options: .regularExpression) != nil {
            return .hindi
        }
        
        // Check for Armenian characters
        let armenianPattern = "[\\u0530-\\u058f]"
        if text.range(of: armenianPattern, options: .regularExpression) != nil {
            return .armenian
        }
        
        // Check for Georgian characters
        let georgianPattern = "[\\u10a0-\\u10ff]"
        if text.range(of: georgianPattern, options: .regularExpression) != nil {
            return .georgian
        }
        
        // Check for Khmer characters
        let khmerPattern = "[\\u1780-\\u17ff]"
        if text.range(of: khmerPattern, options: .regularExpression) != nil {
            return .khmer
        }
        
        // Check for Lao characters
        let laoPattern = "[\\u0e80-\\u0eff]"
        if text.range(of: laoPattern, options: .regularExpression) != nil {
            return .lao
        }
        
        // Check for Tibetan characters
        let tibetanPattern = "[\\u0f00-\\u0fff]"
        if text.range(of: tibetanPattern, options: .regularExpression) != nil {
            return .tibetan
        }
        
        // Check for Mongolian characters
        let mongolianPattern = "[\\u1800-\\u18af]"
        if text.range(of: mongolianPattern, options: .regularExpression) != nil {
            return .mongolian
        }
        
        return nil
    }
    
    private func detectCyrillicLanguage(_ text: String) -> InputLanguage {
        let text = text.lowercased()
        
        // Check for Ukrainian-specific characters
        if text.contains("і") || text.contains("ї") || text.contains("є") || text.contains("ґ") {
            return .ukrainian
        }
        
        // Check for Bulgarian-specific characters
        if text.contains("ъ") {
            return .bulgarian
        }
        
        // Check for Serbian-specific characters (Latin and Cyrillic mixed)
        if text.contains("ђ") || text.contains("ћ") || text.contains("њ") || text.contains("љ") {
            return .croatian // Using Croatian as closest match for Serbian
        }
        
        // Check for Kazakh-specific characters
        if text.contains("ә") || text.contains("ғ") || text.contains("қ") || text.contains("ң") || text.contains("ө") || text.contains("ұ") || text.contains("ү") || text.contains("һ") {
            return .kazakh
        }
        
        // For common Russian words, check against a small dictionary
        let commonRussianWords = [
            "привет", "спасибо", "пожалуйста", "извините", "до свидания", "добро пожаловать",
            "да", "нет", "хорошо", "плохо", "большой", "маленький", "новый", "старый",
            "хороший", "плохой", "красивый", "уродливый", "быстрый", "медленный",
            "горячий", "холодный", "теплый", "прохладный", "светлый", "темный",
            "белый", "черный", "красный", "синий", "зеленый", "желтый", "коричневый"
        ]
        
        if commonRussianWords.contains(text) {
            return .russian
        }
        
        // Check for common Bulgarian words
        let commonBulgarianWords = [
            "здравей", "благодаря", "моля", "извинете", "довиждане", "добре дошли",
            "да", "не", "добре", "лошо", "голям", "малък", "нов", "стар",
            "хубав", "грозен", "бърз", "бавен", "горещ", "студен", "топъл", "хладен"
        ]
        
        if commonBulgarianWords.contains(text) {
            return .bulgarian
        }
        
        // Default to Russian for general Cyrillic text
        // This is a reasonable default since Russian is the most widely used Cyrillic language
        return .russian
    }
}
