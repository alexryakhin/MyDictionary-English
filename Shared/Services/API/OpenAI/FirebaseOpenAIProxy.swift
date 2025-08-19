import Foundation

// MARK: - Firebase OpenAI Proxy Service

final class FirebaseOpenAIProxy: AIServiceInterface {
    static let shared = FirebaseOpenAIProxy()
    
    private let baseURL = "https://europe-west3-my-dictionary-english.cloudfunctions.net/openAIProxy"
    
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
        
        let request = FirebaseOpenAIRequest(
            word: word,
            maxDefinitions: maxDefinitions,
            targetLanguage: targetLanguage ?? getCurrentAppLanguage(),
            userId: userId
        )
        
        print("🚀 [FirebaseOpenAIProxy] Making request to Firebase Functions...")
        
        guard let url = URL(string: baseURL) else {
            print("❌ [FirebaseOpenAIProxy] Invalid URL: \(baseURL)")
            throw CoreError.networkError(.invalidURL)
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try JSONEncoder().encode(request)
        
        print("🔍 [FirebaseOpenAIProxy] Request body: \(String(data: urlRequest.httpBody!, encoding: .utf8) ?? "")")
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ [FirebaseOpenAIProxy] Invalid HTTP response type")
            throw CoreError.networkError(.serverUnreachable)
        }
        
        print("🔍 [FirebaseOpenAIProxy] HTTP status code: \(httpResponse.statusCode)")
        
        if httpResponse.statusCode != 200 {
            print("❌ [FirebaseOpenAIProxy] HTTP error: \(httpResponse.statusCode)")
            if let errorData = String(data: data, encoding: .utf8) {
                print("🔍 [FirebaseOpenAIProxy] Error response: \(errorData)")
            }
            throw CoreError.networkError(.invalidResponse(statusCode: httpResponse.statusCode))
        }
        
        let firebaseResponse = try JSONDecoder().decode(FirebaseOpenAIResponse.self, from: data)
        
        if !firebaseResponse.success {
            print("❌ [FirebaseOpenAIProxy] Firebase function error: \(firebaseResponse.error ?? "Unknown error")")
            throw CoreError.networkError(.serverUnreachable)
        }
        
        guard let responseData = firebaseResponse.data else {
            print("❌ [FirebaseOpenAIProxy] No data in response")
            throw CoreError.networkError(.serverUnreachable)
        }
        
        print("✅ [FirebaseOpenAIProxy] Successfully received response from Firebase Functions")
        print("🔍 [FirebaseOpenAIProxy] Usage - Prompt tokens: \(firebaseResponse.usage?.promptTokens ?? 0)")
        print("🔍 [FirebaseOpenAIProxy] Usage - Completion tokens: \(firebaseResponse.usage?.completionTokens ?? 0)")
        print("🔍 [FirebaseOpenAIProxy] Usage - Total tokens: \(firebaseResponse.usage?.totalTokens ?? 0)")
        
        // Parse the JSON response from OpenAI
        return try parseWordInformationResponse(responseData)
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
