import Foundation

// MARK: - Firebase OpenAI Proxy Service

final class FirebaseOpenAIProxy: AIAPIServiceInterface {

    private let cloudFunctionsService = CloudFunctionsService.shared

    func generateWordInformation(
        for word: String,
        maxDefinitions: Int = 10,
        inputLanguage: InputLanguage,
        userLanguage: String,
        userId: String
    ) async throws -> AIWordResponse {
        print("🔍 [FirebaseOpenAIProxy] generateWordInformation called for word: '\(word)'")
        print("🔍 [FirebaseOpenAIProxy] User ID: \(userId)")
        print("🔍 [FirebaseOpenAIProxy] User language: \(userLanguage)")
        print("🚀 [FirebaseOpenAIProxy] Making request to Firebase Functions...")

        do {
            let response = try await cloudFunctionsService.openAIProxy(
                word: word,
                maxDefinitions: maxDefinitions,
                userLanguage: userLanguage
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
