//
//  InputLanguageTest.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/9/25.
//

import Foundation

class InputLanguageTest {
    
    static func testInputLanguageFunctionality() {
        print("🧪 Testing Input Language Functionality...")
        
        // Test 1: Language display names
        print("\n📝 Language Display Names:")
        for language in InputLanguage.allCases {
            print("   \(language.rawValue) -> \(language.displayName)")
        }
        
        // Test 2: Auto detection logic
        print("\n🤖 Auto Detection Logic:")
        let autoLanguage = InputLanguage.auto
        print("   Is Auto: \(autoLanguage.isAuto)")
        print("   Language Code: \(autoLanguage.languageCode)")
        
        // Test 3: Specific language logic
        print("\n🌍 Specific Language Logic:")
        let englishLanguage = InputLanguage.english
        print("   Is Auto: \(englishLanguage.isAuto)")
        print("   Language Code: \(englishLanguage.languageCode)")
        print("   Display Name: \(englishLanguage.displayName)")
        
        // Test 4: Translation logic simulation
        print("\n🔄 Translation Logic Simulation:")
        let testCases = [
            (InputLanguage.auto, "bonjour"),
            (InputLanguage.french, "bonjour"),
            (InputLanguage.english, "hello"),
            (InputLanguage.spanish, "hola")
        ]
        
        for (language, word) in testCases {
            let shouldAutoDetect = language.isAuto
            let sourceLanguage = shouldAutoDetect ? "auto" : language.languageCode
            print("   \(language.displayName) + '\(word)' -> Source: \(sourceLanguage)")
        }
        
        // Test 5: Locale-specific display names
        print("\n🌐 Locale-Specific Display Names:")
        let testLanguages = [InputLanguage.french, InputLanguage.spanish, InputLanguage.german, InputLanguage.japanese]
        for language in testLanguages {
            let localizedName = Locale.current.localizedString(forLanguageCode: language.languageCode)?.capitalized ?? language.languageCode.uppercased()
            print("   \(language.languageCode) -> \(localizedName)")
        }
    }
} 