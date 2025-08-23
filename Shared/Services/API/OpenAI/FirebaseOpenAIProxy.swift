import Foundation

// MARK: - Firebase OpenAI Proxy Service

final class FirebaseOpenAIProxy: AIServiceInterface {
    static let shared = FirebaseOpenAIProxy()

    private init() {}
    
    func generateWordInformation(
        for word: String,
        maxDefinitions: Int = 5,
        targetLanguage: String? = nil,
        userId: String
    ) async throws -> AIWordResponse {
        print("🔍 [FirebaseOpenAIProxy] generateWordInformation called for word: '\(word)'")
        print("🔍 [FirebaseOpenAIProxy] User ID: \(userId)")
        print("🔍 [FirebaseOpenAIProxy] Target language: \(targetLanguage ?? "auto-detect")")
        
        print("🚀 [FirebaseOpenAIProxy] Making request to Firebase Functions...")
        
        do {
            let response = try await CloudFunctionsService.shared.openAIProxy(
                word: word,
                maxDefinitions: maxDefinitions,
                targetLanguage: targetLanguage ?? getCurrentAppLanguage()
            )
            
            print("✅ [FirebaseOpenAIProxy] Successfully received response from Firebase Functions")
            print("🔍 [FirebaseOpenAIProxy] Usage - Prompt tokens: \(response.usage?.promptTokens ?? 0)")
            print("🔍 [FirebaseOpenAIProxy] Usage - Completion tokens: \(response.usage?.completionTokens ?? 0)")
            print("🔍 [FirebaseOpenAIProxy] Usage - Total tokens: \(response.usage?.totalTokens ?? 0)")
            
            // Parse the JSON response from OpenAI
            return try parseWordInformationResponse(response.data)
        } catch {
            print("❌ [FirebaseOpenAIProxy] Error: \(error.localizedDescription)")
            throw CoreError.networkError(.serverUnreachable)
        }
    }
    
    // MARK: - Private Methods
    
    private func getCurrentAppLanguage() -> String {
        let preferredLanguage = Locale.preferredLanguages.first ?? "en"
        let languageCode = preferredLanguage.prefix(2).lowercased()
        
        // Map common language codes to full language names for better AI prompts
        let languageMap: [String: String] = [
            "en": "English",
            "es": "Spanish", 
            "fr": "French",
            "de": "German",
            "it": "Italian",
            "pt": "Portuguese",
            "ru": "Russian",
            "ja": "Japanese",
            "ko": "Korean",
            "zh": "Chinese",
            "ar": "Arabic",
            "hi": "Hindi",
            "th": "Thai",
            "vi": "Vietnamese",
            "tr": "Turkish",
            "pl": "Polish",
            "nl": "Dutch",
            "sv": "Swedish",
            "da": "Danish",
            "no": "Norwegian",
            "fi": "Finnish",
            "cs": "Czech",
            "sk": "Slovak",
            "hu": "Hungarian",
            "ro": "Romanian",
            "bg": "Bulgarian",
            "hr": "Croatian",
            "sl": "Slovenian",
            "et": "Estonian",
            "lv": "Latvian",
            "lt": "Lithuanian",
            "el": "Greek",
            "he": "Hebrew",
            "id": "Indonesian",
            "ms": "Malay",
            "ca": "Catalan",
            "uk": "Ukrainian"
        ]
        
        return languageMap[languageCode] ?? "English"
    }
    
    private func parseWordInformationResponse(_ response: String) throws -> AIWordResponse {
        print("🔍 [FirebaseOpenAIProxy] Parsing JSON response...")
        
        // Clean the response - remove any extra text before or after JSON
        let cleanedResponse = cleanJSONResponse(response)
        print("🔍 [FirebaseOpenAIProxy] Cleaned response: \(cleanedResponse)")
        
        do {
            let jsonData = cleanedResponse.data(using: .utf8)!
            let openAIResponse = try JSONDecoder().decode(OpenAIWordResponse.self, from: jsonData)
            
            print("✅ [FirebaseOpenAIProxy] Successfully parsed JSON with \(openAIResponse.definitions.count) definitions")
            print("🔍 [FirebaseOpenAIProxy] Pronunciation: \(openAIResponse.pronunciation)")
            
            return AIWordResponse(
                definitions: openAIResponse.definitions,
                pronunciation: openAIResponse.pronunciation
            )
        } catch {
            print("❌ [FirebaseOpenAIProxy] JSON parsing failed: \(error.localizedDescription)")
            throw CoreError.networkError(.serverUnreachable)
        }
    }
    
    private func cleanJSONResponse(_ response: String) -> String {
        // Remove any text before the first {
        if let startIndex = response.firstIndex(of: "{") {
            let jsonStart = String(response[startIndex...])
            
            // Find the last } to get complete JSON
            if let endIndex = jsonStart.lastIndex(of: "}") {
                let jsonEnd = String(jsonStart[...endIndex])
                return jsonEnd
            }
        }
        
        return response
    }
}
