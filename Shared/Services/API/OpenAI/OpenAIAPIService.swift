//
//  OpenAIAPIService.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/9/25.
//

import Foundation

#if DEBUG


// MARK: - OpenAI API Service

final class OpenAIAPIService: AIServiceInterface {

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
        maxDefinitions: Int = 5,
        targetLanguage: String? = nil,
        userId: String
    ) async throws -> AIWordResponse {
        print("🔍 [OpenAIAPIService] generateWordInformation called for word: '\(word)'")
        print("🔍 [OpenAIAPIService] Max definitions: \(maxDefinitions)")
        print("🔍 [OpenAIAPIService] Target language: \(targetLanguage ?? "auto-detect")")
        print("🔍 [OpenAIAPIService] User ID: \(userId)")

        let finalTargetLanguage = targetLanguage ?? getCurrentAppLanguage()
        print("🔍 [OpenAIAPIService] Final target language: \(finalTargetLanguage)")

        let prompt = buildWordInformationPrompt(
            word: word,
            maxDefinitions: maxDefinitions,
            targetLanguage: finalTargetLanguage
        )

        print("🔍 [OpenAIAPIService] Built prompt for OpenAI")

        do {
            let response = try await makeOpenAIRequest(prompt: prompt)
            print("✅ [OpenAIAPIService] Received response from OpenAI")

            let wordInfo = parseWordInformationResponse(response)
            print("✅ [OpenAIAPIService] Parsed response with \(wordInfo.definitions.count) definitions")

            return wordInfo
        } catch {
            print("❌ [OpenAIAPIService] Failed to generate word information: \(error.localizedDescription)")
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
        targetLanguage: String
    ) -> String {
        let prompt = """
        Provide information for the word '\(word)' in \(targetLanguage) in the following JSON format:
        
        {
          "pronunciation": "[phonetic pronunciation]",
          "definitions": [
            {
              "partOfSpeech": "[Part of Speech in English]",
              "definition": "[1-3 sentence definition in \(targetLanguage)]",
              "examples": [
                "[1-2 sentence example in the language of the input word]",
                "[1-2 sentence example in the language of the input word]"
              ]
            }
          ]
        }
        
        IMPORTANT RULES:
        1. Return ONLY valid JSON - no additional text before or after
        2. Definition must be in the \(targetLanguage). Examples should be in the language of the input word.
        3. Pronunciation should be of the original input word using International Phonetic Alphabet
        4. If the input word is in a different language, provide definition in the \(targetLanguage), but do not translate the word.
        5. Keep definitions concise (1-3 sentences) and examples practical (1-2 sentences each)
        6. Include the most common meanings first
        7. Provide up to \(maxDefinitions) definitions
        8. Each definition should have 2-3 examples
        9. Use proper JSON escaping for quotes and special characters
        """

        print("🔍 [OpenAIAPIService] Built prompt for word '\(word)' in \(targetLanguage)")
        return prompt
    }

    private func parseWordInformationResponse(_ response: String) -> AIWordResponse {
        print("🔍 [OpenAIAPIService] Parsing JSON response...")

        let cleanedResponse = cleanJSONResponse(response)
        print("🔍 [OpenAIAPIService] Cleaned response: \(cleanedResponse)")

        do {
            let decoder = JSONDecoder()
            let openAIResponse = try decoder.decode(OpenAIWordResponse.self, from: cleanedResponse.data(using: .utf8)!)

            let wordResponse = AIWordResponse(
                definitions: openAIResponse.definitions,
                pronunciation: openAIResponse.pronunciation
            )

            print("✅ [OpenAIAPIService] Successfully parsed JSON with \(wordResponse.definitions.count) definitions")
            print("🔍 [OpenAIAPIService] Pronunciation: \(wordResponse.pronunciation)")

            return wordResponse
        } catch {
            print("❌ [OpenAIAPIService] JSON parsing failed: \(error.localizedDescription)")
            print("🔄 [OpenAIAPIService] Falling back to text parsing...")
            return parseWordInformationResponseFallback(response)
        }
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

    private func parseWordInformationResponseFallback(_ response: String) -> AIWordResponse {
        print("🔍 [OpenAIAPIService] Using fallback text parsing...")

        var definitions: [AIWordDefinition] = []
        var pronunciation = ""

        let lines = response.components(separatedBy: .newlines)
        var currentDefinition: String?
        var currentPartOfSpeech: String?
        var currentExamples: [String] = []

        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)

            if trimmedLine.isEmpty { continue }

            // Check for pronunciation
            if trimmedLine.contains("Pronunciation:") || trimmedLine.contains("произношение:") {
                pronunciation = trimmedLine.replacingOccurrences(of: "Pronunciation:", with: "")
                    .replacingOccurrences(of: "произношение:", with: "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .replacingOccurrences(of: "[", with: "")
                    .replacingOccurrences(of: "]", with: "")
                continue
            }

            // Check for new definition (numbered)
            if let range = trimmedLine.range(of: #"^\d+\."#, options: .regularExpression) {
                // Save previous definition if exists
                if let def = currentDefinition, let pos = currentPartOfSpeech {
                    definitions.append(AIWordDefinition(
                        partOfSpeech: pos,
                        definition: def,
                        examples: currentExamples
                    ))
                }

                // Start new definition
                let definitionText = String(trimmedLine[range.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
                currentDefinition = definitionText
                currentExamples = []

                // Try to extract part of speech
                if let dotRange = definitionText.range(of: ". ") {
                    currentPartOfSpeech = String(definitionText[..<dotRange.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
                    currentDefinition = String(definitionText[dotRange.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
                } else {
                    currentPartOfSpeech = "noun" // Default
                }
                continue
            }

            // Check for examples (usually start with dash or bullet)
            if trimmedLine.hasPrefix("-") || trimmedLine.hasPrefix("•") || trimmedLine.hasPrefix("*") {
                let example = trimmedLine.replacingOccurrences(of: "-", with: "")
                    .replacingOccurrences(of: "•", with: "")
                    .replacingOccurrences(of: "*", with: "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                currentExamples.append(example)
                continue
            }

            // If we have a current definition, append to it
            if currentDefinition != nil {
                currentDefinition = (currentDefinition ?? "") + " " + trimmedLine
            }
        }

        // Add the last definition
        if let def = currentDefinition, let pos = currentPartOfSpeech {
            definitions.append(AIWordDefinition(
                partOfSpeech: pos,
                definition: def,
                examples: currentExamples
            ))
        }

        print("🔍 [OpenAIAPIService] Fallback parsing found \(definitions.count) definitions")

        return AIWordResponse(
            definitions: definitions,
            pronunciation: pronunciation.isEmpty ? "[pronunciation]" : pronunciation
        )
    }

    private func getCurrentAppLanguage() -> String {
        let preferredLanguage = Locale.preferredLanguages.first ?? "en"
        let languageCode = preferredLanguage.prefix(2).lowercased()

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
            "th": "Thai",
            "vi": "Vietnamese",
            "id": "Indonesian",
            "ms": "Malay"
        ]

        return languageMap[languageCode] ?? "English"
    }
}

#endif
