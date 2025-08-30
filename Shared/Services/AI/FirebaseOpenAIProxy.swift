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
        let response = try await cloudFunctionsService.openAIProxy(
            word: word,
            maxDefinitions: maxDefinitions,
            inputLanguage: inputLanguage.englishName,
            userLanguage: userLanguage
        )
        return try parseWordInformationResponse(response.data)
    }

    // MARK: - Private Methods

    private func parseWordInformationResponse(_ response: String) throws -> AIWordResponse {
        print("🔍 [FirebaseOpenAIProxy] Parsing JSON response...")

        // Clean the response - remove any extra text before or after JSON
        let cleanedResponse = cleanJSONResponse(response)

        let openAIResponse = try JSONDecoder().decode(
            OpenAIWordResponse.self,
            from: cleanedResponse.data(using: .utf8)!
        )

        let wordResponse = AIWordResponse(
            definitions: openAIResponse.definitions,
            pronunciation: openAIResponse.pronunciation
        )

        return wordResponse
    }

    private func cleanJSONResponse(_ response: String) -> String {
        var cleaned = response.trimmingCharacters(in: .whitespacesAndNewlines)

        // Remove markdown code blocks if present
        if cleaned.hasPrefix("```json") {
            cleaned = String(cleaned.dropFirst(7))
        }
        if cleaned.hasPrefix("```") {
            cleaned = String(cleaned.dropFirst(3))
        }
        if cleaned.hasSuffix("```") {
            cleaned = String(cleaned.dropLast(3))
        }

        cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
        return cleaned
    }
}
