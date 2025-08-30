//
//  OpenAIAPIService.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/9/25.
//

import Foundation

#if DEBUG

// MARK: - OpenAI API Service

final class OpenAIAPIService: AIAPIServiceInterface {

    // MARK: - Properties

    private let baseURL = "https://api.openai.com/v1/chat/completions"
    private let apiKey: String
    private let organization: String
    private let projectID: String

    // MARK: - Initialization

    init() {
        // In debug mode, you can set your API key here for local development
        // IMPORTANT: This will NOT be included in release builds
        self.apiKey = GlobalConstant.openAIAPIKey // Replace with your actual API key for local development
        self.organization = GlobalConstant.openAIOrganization
        self.projectID = GlobalConstant.openAIProjectID

        print("🔧 [OpenAIAPIService] Initialized for DEBUG mode")
        print("⚠️ [OpenAIAPIService] Using direct OpenAI API calls - API key should be set for local development")
    }

    // MARK: - Public Methods

    func generateWordInformation(
        for word: String,
        maxDefinitions: Int = 10,
        inputLanguage: InputLanguage,
        userLanguage: String,
        userId: String
    ) async throws -> AIWordResponse {
        print("🔍 [OpenAIAPIService] generateWordInformation called for word: '\(word)'")
        print("🔍 [OpenAIAPIService] Max definitions: \(maxDefinitions)")
        print("🔍 [OpenAIAPIService] User ID: \(userId)")
        print("🔍 [OpenAIAPIService] User language: \(userLanguage)")

        let prompt = buildWordInformationPrompt(
            word: word,
            maxDefinitions: maxDefinitions,
            inputLanguage: inputLanguage.englishName,
            userLanguage: userLanguage
        )

        print("🔍 [OpenAIAPIService] Built prompt for OpenAI")

        do {
            let response = try await makeOpenAIRequest(prompt: prompt)
            print("✅ [OpenAIAPIService] Received response from OpenAI")

            let wordInfo = try parseWordInformationResponse(response)
            print("✅ [OpenAIAPIService] Parsed response with \(wordInfo.definitions.count) definitions")

            return wordInfo
        } catch {
            print("❌ [OpenAIAPIService] Failed to generate word information: \(error.localizedDescription)")
            throw error
        }
    }

    func generateRelatedWords(
        for word: String,
        context: String,
        maxWords: Int,
        userId: String
    ) async throws -> [AIRelatedWordWithDefinition] {
        print("🔍 [OpenAIAPIService] generateRelatedWords called for word: '\(word)'")
        print("🔍 [OpenAIAPIService] Context: \(context)")
        print("🔍 [OpenAIAPIService] Max words: \(maxWords)")
        print("🔍 [OpenAIAPIService] User ID: \(userId)")

        let prompt = buildRelatedWordsPrompt(
            word: word,
            context: context,
            maxWords: maxWords
        )

        print("🔍 [OpenAIAPIService] Built prompt for related words")

        do {
            let response = try await makeOpenAIRequest(prompt: prompt)
            print("✅ [OpenAIAPIService] Received response for related words")

            let relatedWords = try parseRelatedWordsResponse(response)
            print("✅ [OpenAIAPIService] Parsed \(relatedWords.count) related words")

            return relatedWords
        } catch {
            print("❌ [OpenAIAPIService] Failed to generate related words: \(error.localizedDescription)")
            throw error
        }
    }

    // MARK: - Private Methods

    private func makeOpenAIRequest(prompt: String) async throws -> String {
        print("🚀 [OpenAIAPIService] Making OpenAI API request...")

        let request = OpenAIRequest(
            model: "gpt-4o-mini",
            messages: [
                OpenAIMessage(role: "user", content: prompt)
            ],
            temperature: 0.7,
            maxTokens: 1000
        )

        var urlRequest = URLRequest(url: URL(string: baseURL)!)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue(organization, forHTTPHeaderField: "OpenAI-Organization")
        urlRequest.setValue(projectID, forHTTPHeaderField: "OpenAI-Project")

        urlRequest.httpBody = try JSONEncoder().encode(request)

        print("🔍 [OpenAIAPIService] Sending request to OpenAI...")

        let (data, response) = try await URLSession.shared.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "OpenAIAPIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }

        print("🔍 [OpenAIAPIService] HTTP status code: \(httpResponse.statusCode)")

        guard httpResponse.statusCode == 200 else {
            let errorString = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("❌ [OpenAIAPIService] OpenAI API error: \(errorString)")
            throw NSError(domain: "OpenAIAPIService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorString])
        }

        let openAIResponse = try JSONDecoder().decode(OpenAIResponse.self, from: data)

        print("🔍 [OpenAIAPIService] OpenAI usage - Prompt tokens: \(openAIResponse.usage.promptTokens)")
        print("🔍 [OpenAIAPIService] OpenAI usage - Completion tokens: \(openAIResponse.usage.completionTokens)")
        print("🔍 [OpenAIAPIService] OpenAI usage - Total tokens: \(openAIResponse.usage.totalTokens)")

        guard let content = openAIResponse.choices.first?.message.content else {
            throw NSError(domain: "OpenAIAPIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No content in response"])
        }

        print("✅ [OpenAIAPIService] Successfully extracted content from OpenAI response")
        return content
    }

    private func buildWordInformationPrompt(
        word: String,
        maxDefinitions: Int,
        inputLanguage: String,
        userLanguage: String
    ) -> String {
        let prompt = """
        IMPORTANT: This is for EDUCATIONAL PURPOSES in a language learning application. User's language is \(userLanguage), and he/she learns \(inputLanguage). Provide comprehensive information for the word/phrase '\(word)' in \(userLanguage) and examples in \(inputLanguage) in the following JSON format:
        
        {
          "pronunciation": "[phonetic pronunciation]",
          "definitions": [
            {
              "partOfSpeech": "[Part of Speech in English]",
              "definition": "[1-3 sentence definition in \(userLanguage)]",
              "examples": [
                "[1-2 sentence example in \(inputLanguage)]",
                "[1-2 sentence example in \(inputLanguage)]"
              ]
            }
          ]
        }
        
        IMPORTANT RULES:
        1. Return ONLY valid JSON - no additional text before or after
        2. Definition must be in the \(userLanguage). Examples must be in \(inputLanguage) (the language of the input word).
        3. Part of speech should be chosen from: 'noun', 'verb', 'adjective', 'adverb', 'conjunction', 'pronoun', 'preposition', 'exclamation', 'interjection', 'idiom', 'phrase', 'unknown'.
        4. Pronunciation should be of the original input word using International Phonetic Alphabet
        5. Focus on COMMON, EVERYDAY meanings and uses first, not just religious or specialized meanings
        6. Include different meanings and contexts - avoid repetitive definitions that mean the same thing
        7. For phrases and expressions, include both literal and figurative meanings
        8. Include idiomatic uses, slang, and colloquial expressions when applicable
        9. Keep definitions concise (1-3 sentences) and examples practical (1-2 sentences each)
        10. Provide up to \(maxDefinitions) distinct definitions
        11. Each definition should have 2-3 examples
        12. Use proper JSON escaping for quotes and special characters
        13. If the word/phrase has multiple distinct meanings, prioritize the most commonly used ones in everyday language
        14. For religious names/phrases, also include their use as exclamations, expressions of surprise, or in casual speech
        15. Include both formal and informal usage contexts
        16. As this is for educational purposes, include ALL meanings including slang, profanity, and informal expressions when they exist
        17. Provide accurate linguistic information regardless of content sensitivity - this helps language learners understand real-world usage
        18. CRITICAL: Definitions should NOT mention the input word itself - they should explain the concept without using the word being defined (this is essential for quiz functionality)
        """

        print("🔍 [OpenAIAPIService] Built prompt for word '\(word)' in \(userLanguage)")
        return prompt
    }

    private func buildRelatedWordsPrompt(
        word: String,
        context: String,
        maxWords: Int
    ) -> String {
        let prompt = """
            IMPORTANT: This is for EDUCATIONAL PURPOSES in a language learning application. Based on the provided word and context, generate a list of semantically related words that would be useful for vocabulary learning.
            
            Word: \(word)
            Context: \(context)
            
            Provide up to \(maxWords) related words in the following JSON format:
            
            {
              "relatedWords": [
                {
                  "word": "[related word]",
                  "definition": "[1-2 sentence definition explaining the relationship or meaning]",
                  "example": "[1 sentence example showing usage]",
                  "partOfSpeech": "[noun, verb, adjective, adverb, etc.]"
                }
              ]
            }
            
            IMPORTANT RULES:
            1. Return ONLY valid JSON - no additional text before or after
            2. Focus on words that are semantically related to the input word
            3. Include synonyms, antonyms, hypernyms, hyponyms, and contextually related words
            4. Definitions should be clear and educational
            5. Examples should be practical and show real usage
            6. Part of speech should be accurate
            7. Avoid very obscure or technical words unless they're directly related
            8. Prioritize words that would be useful for vocabulary building
            9. Use proper JSON escaping for quotes and special characters
            10. Each word should have a clear relationship to the input word
            """

        return prompt
    }

    private func parseWordInformationResponse(_ response: String) throws -> AIWordResponse {
        print("🔍 [OpenAIAPIService] Parsing JSON response...")
        print("🔍 [FirebaseOpenAIProxy] Response: \(response)")

        let cleanedResponse = cleanJSONResponse(response)
        print("🔍 [OpenAIAPIService] Cleaned response: \(cleanedResponse)")

        let openAIResponse = try JSONDecoder().decode(
            OpenAIWordResponse.self,
            from: cleanedResponse.data(using: .utf8)!
        )

        let wordResponse = AIWordResponse(
            definitions: openAIResponse.definitions,
            pronunciation: openAIResponse.pronunciation
        )

        print("✅ [OpenAIAPIService] Successfully parsed JSON with \(wordResponse.definitions.count) definitions")
        print("🔍 [OpenAIAPIService] Pronunciation: \(wordResponse.pronunciation)")

        return wordResponse
    }

    private func parseRelatedWordsResponse(_ response: String) throws -> [AIRelatedWordWithDefinition] {
        print("🔍 [OpenAIAPIService] Parsing related words response...")

        let cleanedResponse = cleanJSONResponse(response)
        print("🔍 [OpenAIAPIService] Cleaned response: \(cleanedResponse)")

        let openAIResponse = try JSONDecoder().decode(
            OpenAIRelatedWordsResponse.self,
            from: cleanedResponse.data(using: .utf8)!
        )

        let relatedWords = openAIResponse.relatedWords.map { wordData in
            AIRelatedWordWithDefinition(
                word: wordData.word,
                definition: wordData.definition,
                example: wordData.example,
                partOfSpeech: wordData.partOfSpeech
            )
        }

        print("✅ [OpenAIAPIService] Successfully parsed \(relatedWords.count) related words")
        return relatedWords
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

#endif
