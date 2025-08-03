//
//  TranslationTest.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/9/25.
//

import Foundation

class TranslationTest {
    
    static func testTranslationService() async {
        let service = GoogleTranslateService()
        
        print("🧪 Testing Translation Service...")
        
        // Test 1: French word translation
        do {
            let response = try await service.translateToEnglish("bonjour")
            print("✅ French word test passed:")
            print("   Input: 'bonjour'")
            print("   Translated: '\(response.text)'")
            print("   Detected language: '\(response.languageCode)'")
            print("   Should request pronunciation: \(response.languageCode == "en")")
        } catch {
            print("❌ French word test failed: \(error)")
        }
        
        // Test 2: English word translation
        do {
            let response = try await service.translateToEnglish("hello")
            print("✅ English word test passed:")
            print("   Input: 'hello'")
            print("   Translated: '\(response.text)'")
            print("   Detected language: '\(response.languageCode)'")
            print("   Should request pronunciation: \(response.languageCode == "en")")
        } catch {
            print("❌ English word test failed: \(error)")
        }
        
        // Test 3: Definition translation
        do {
            let translatedDefinition = try await service.translateDefinition("A greeting used to say hello", to: "fr")
            print("✅ Definition translation test passed:")
            print("   Input: 'A greeting used to say hello'")
            print("   Translated: '\(translatedDefinition)'")
        } catch {
            print("❌ Definition translation test failed: \(error)")
        }
        
        // Test 4: Locale detection
        let languageCode = Locale.current.language.languageCode?.identifier ?? "en"
        let isEnglishLocale = languageCode == "en"
        
        print("🌍 Locale detection test:")
        print("   Language code: \(languageCode)")
        print("   Is English locale: \(isEnglishLocale)")
        print("   Should show translation setting: \(!isEnglishLocale)")
    }
} 