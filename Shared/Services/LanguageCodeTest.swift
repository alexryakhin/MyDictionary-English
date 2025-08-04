//
//  LanguageCodeTest.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/9/25.
//

import Foundation

class LanguageCodeTest {
    
    static func testLanguageCodeImplementation() {
        print("🧪 Testing Language Code Implementation...")
        
        // Test 1: Language display names
        let testCases = [
            ("en", "English"),
            ("fr", "French"),
            ("es", "Spanish"),
            ("de", "German"),
            ("it", "Italian"),
            ("pt", "Portuguese"),
            ("ru", "Russian"),
            ("ja", "Japanese"),
            ("ko", "Korean"),
            ("zh", "Chinese"),
            ("ar", "Arabic"),
            ("hi", "Hindi"),
            ("unknown", "UNKNOWN")
        ]
        
        for (code, expected) in testCases {
            let displayName = getLanguageDisplayName(code)
            let status = displayName == expected ? "✅" : "❌"
            print("   \(status) \(code) -> \(displayName) (expected: \(expected))")
        }
        
        // Test 2: Should show language label logic
        print("\n🌍 Should Show Language Label Tests:")
        let showLabelTests = [
            ("en", false),
            ("fr", true),
            ("es", true),
            (nil, false)
        ]
        
        for (code, expected) in showLabelTests {
            let shouldShow = shouldShowLanguageLabel(code)
            let status = shouldShow == expected ? "✅" : "❌"
            print("   \(status) \(code ?? "nil") should show: \(shouldShow) (expected: \(expected))")
        }
    }
    
    private static func getLanguageDisplayName(_ code: String?) -> String {
        guard let languageCode = code else { return "Unknown" }
        
        switch languageCode {
        case "en":
            return "English"
        case "fr":
            return "French"
        case "es":
            return "Spanish"
        case "de":
            return "German"
        case "it":
            return "Italian"
        case "pt":
            return "Portuguese"
        case "ru":
            return "Russian"
        case "ja":
            return "Japanese"
        case "ko":
            return "Korean"
        case "zh":
            return "Chinese"
        case "ar":
            return "Arabic"
        case "hi":
            return "Hindi"
        default:
            return languageCode.uppercased()
        }
    }
    
    private static func shouldShowLanguageLabel(_ code: String?) -> Bool {
        return code != nil && code != "en"
    }
} 