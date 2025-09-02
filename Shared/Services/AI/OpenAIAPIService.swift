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

    func evaluateSentences(
        sentences: [(sentence: String, targetWord: String)],
        userId: String,
        userLanguage: String
    ) async throws -> [AISentenceEvaluation] {
        print("🔍 [OpenAIAPIService] evaluateSentences called for \(sentences.count) sentences")
        print("🔍 [OpenAIAPIService] User ID: \(userId)")

        let prompt = buildSentencesEvaluationPrompt(
            sentences: sentences,
            userLanguage: userLanguage
        )

        print("🔍 [OpenAIAPIService] Built prompt for sentences evaluation")

        do {
            let response = try await makeOpenAIRequest(prompt: prompt)
            print("✅ [OpenAIAPIService] Received response for sentences evaluation")

            let evaluations = try parseSentencesEvaluationResponse(response)
            print("✅ [OpenAIAPIService] Parsed \(evaluations.count) sentence evaluations")

            return evaluations
        } catch {
            print("❌ [OpenAIAPIService] Failed to evaluate sentences: \(error.localizedDescription)")
            throw error
        }
    }

    func generateSingleContextQuestion(
        word: String,
        wordLanguage: String,
        userId: String,
        userLanguage: String
    ) async throws -> AIContextQuestion {
        print("🔍 [OpenAIAPIService] generateSingleContextQuestion called for word: '\(word)' in language: '\(wordLanguage)'")
        print("🔍 [OpenAIAPIService] User ID: \(userId)")

        let prompt = buildSingleContextQuestionPrompt(word: word, wordLanguage: wordLanguage, userLanguage: userLanguage)

        print("🔍 [OpenAIAPIService] Built prompt for single context question")

        do {
            let response = try await makeOpenAIRequest(prompt: prompt)
            print("✅ [OpenAIAPIService] Received response for single context question")

            let contextQuestion = try parseSingleContextQuestionResponse(response)
            print("✅ [OpenAIAPIService] Parsed single context question")

            return contextQuestion
        } catch {
            print("❌ [OpenAIAPIService] Failed to generate single context question: \(error.localizedDescription)")
            throw error
        }
    }

    func generateSingleFillInTheBlankStory(
        word: String,
        wordLanguage: String,
        userId: String,
        userLanguage: String
    ) async throws -> AIFillInTheBlankStory {
        print("🔍 [OpenAIAPIService] generateSingleFillInTheBlankStory called for word: '\(word)' in language: '\(wordLanguage)'")
        print("🔍 [OpenAIAPIService] User ID: \(userId)")

        let prompt = buildSingleFillInTheBlankStoryPrompt(word: word, wordLanguage: wordLanguage, userLanguage: userLanguage)

        print("🔍 [OpenAIAPIService] Built prompt for single fill in the blank story")

        do {
            let response = try await makeOpenAIRequest(prompt: prompt)
            print("✅ [OpenAIAPIService] Received response for single fill in the blank story")

            let story = try parseSingleFillInTheBlankStoryResponse(response)
            print("✅ [OpenAIAPIService] Parsed single fill in the blank story")

            return story
        } catch {
            print("❌ [OpenAIAPIService] Failed to generate single fill in the blank story: \(error.localizedDescription)")
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
            maxTokens: 2000
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
        18. CRITICAL: Definitions should NOT mention the input word itself - they should explain the concept without using the word being defined (this is essential for quiz functionality), but examples should include the word so a student will see a real usage.
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

    private func buildSentencesEvaluationPrompt(
        sentences: [(sentence: String, targetWord: String)],
        userLanguage: String
    ) -> String {
        let sentencesList = sentences.enumerated().map { index, item in
            "\(index + 1). Target Word: '\(item.targetWord)' | Sentence: '\(item.sentence)'"
        }.joined(separator: "\n")

        let prompt = """
            IMPORTANT: This is for EDUCATIONAL PURPOSES in a language learning application. Evaluate the given sentences for correct usage of their target words.
            
            User Language: \(userLanguage)
            
            Sentences to evaluate:
            \(sentencesList)
            
            Evaluate each sentence and provide feedback in \(userLanguage) in the following JSON format:
            
            {
              "evaluations": [
                {
                  "targetWord": "\(sentences[0].targetWord)",
                  "sentence": "\(sentences[0].sentence)",
                  "usageScore": [0-100 score for correct word usage and meaning],
                  "grammarScore": [0-100 score for grammar and syntax],
                  "overallScore": [0-100 overall score combining usage and grammar],
                  "feedback": "[2-3 sentence detailed feedback explaining the evaluation in \(userLanguage)]",
                  "isCorrect": [true if overall score >= 60, false otherwise],
                  "suggestions": [
                    "[specific suggestion for improvement in \(userLanguage)]",
                    "[another suggestion if applicable in \(userLanguage)]"
                  ]
                }
              ]
            }
            
            IMPORTANT RULES:
            1. Return ONLY valid JSON - no additional text before or after
            2. Evaluate each sentence independently
            3. Usage score focuses on whether the word is used correctly in context
            4. Grammar score focuses on sentence structure and syntax
            5. Overall score should be a weighted average (usage 70%, grammar 30%)
            6. Feedback should be educational and constructive in \(userLanguage)
            7. isCorrect should be true if the word is used correctly (overall score >= 60)
            8. Suggestions should be specific and actionable in \(userLanguage)
            9. Use proper JSON escaping for quotes and special characters
            10. Be encouraging but honest about mistakes
            11. Consider context, meaning, and natural language usage
            12. All feedback and suggestions must be in \(userLanguage)
            """

        return prompt
    }

    private func buildSingleContextQuestionPrompt(
        word: String,
        wordLanguage: String,
        userLanguage: String
    ) -> String {
        let prompt = """
            IMPORTANT: This is for EDUCATIONAL PURPOSES in a language learning application. Create a multiple choice question to test understanding of word usage in context.
            
            Word Language: \(wordLanguage)
            User Language: \(userLanguage)
            
            Word to create question for: '\(word)' (in \(wordLanguage))
            
            Create one question with 4 options in the following JSON format:
            
            {
              "question": {
                "word": "\(word)",
                "question": "Choose the sentence where '\(word)' is used correctly:",
                "options": [
                  {
                    "text": "[sentence in \(wordLanguage) using the word incorrectly or in wrong context]",
                    "isCorrect": false,
                    "explanation": "[brief explanation of why this usage is incorrect in \(userLanguage)]"
                  },
                  {
                    "text": "[sentence in \(wordLanguage) using the word correctly]",
                    "isCorrect": true,
                    "explanation": "[brief explanation of why this usage is correct in \(userLanguage)]"
                  },
                  {
                    "text": "[sentence in \(wordLanguage) using the word incorrectly or in wrong context]",
                    "isCorrect": false,
                    "explanation": "[brief explanation of why this usage is incorrect in \(userLanguage)]"
                  },
                  {
                    "text": "[sentence in \(wordLanguage) using the word incorrectly or in wrong context]",
                    "isCorrect": false,
                    "explanation": "[brief explanation of why this usage is incorrect in \(userLanguage)]"
                  }
                ],
                "correctOptionIndex": [1-based index of the correct option],
                "explanation": "[detailed explanation of the correct answer and why other options are wrong in \(userLanguage)]"
              }
            }
            
            IMPORTANT RULES:
            1. Return ONLY valid JSON - no additional text before or after
            2. Only ONE option should be correct (isCorrect: true)
            3. All sentences must be in \(wordLanguage) (the word's language)
            4. Only explanations should be in \(userLanguage) (the user's language)
            5. Incorrect options should show common mistakes or wrong contexts in \(wordLanguage)
            6. Sentences should be natural and realistic in \(wordLanguage)
            7. correctOptionIndex should be 1, 2, 3, or 4 (1-based indexing)
            8. Explanations should be educational and clear in \(userLanguage)
            9. Use proper JSON escaping for quotes and special characters
            10. Make the question challenging but fair
            11. Consider different meanings and contexts of the word in \(wordLanguage)
            12. Ensure the correct answer is clearly the best choice
            """

        return prompt
    }

    private func buildSingleFillInTheBlankStoryPrompt(
        word: String,
        wordLanguage: String,
        userLanguage: String
    ) -> String {
        let prompt = """
            IMPORTANT: This is for EDUCATIONAL PURPOSES in a language learning application. Create a multiple-choice fill-in-the-blank story for vocabulary practice.
            
            Word Language: \(wordLanguage)
            User Language: \(userLanguage)
            
            Word to create story for: '\(word)' (in \(wordLanguage))
            
            Create one story in the following JSON format:
            
            {
              "story": {
                "word": "\(word)",
                "story": "[short story in \(wordLanguage) (2-3 sentences) with a blank space where the word should go. Use '___' to represent the blank]",
                "options": [
                  {
                    "text": "[correct word/phrase in \(wordLanguage)]",
                    "isCorrect": true,
                    "explanation": "[explanation of why this is correct in \(userLanguage)]"
                  },
                  {
                    "text": "[incorrect option 1 in \(wordLanguage)]",
                    "isCorrect": false,
                    "explanation": "[explanation of why this is incorrect in \(userLanguage)]"
                  },
                  {
                    "text": "[incorrect option 2 in \(wordLanguage)]",
                    "isCorrect": false,
                    "explanation": "[explanation of why this is incorrect in \(userLanguage)]"
                  },
                  {
                    "text": "[incorrect option 3 in \(wordLanguage)]",
                    "isCorrect": false,
                    "explanation": "[explanation of why this is incorrect in \(userLanguage)]"
                  }
                ],
                "correctOptionIndex": [1-based index of the correct option],
                "explanation": "[overall explanation of the story and correct answer in \(userLanguage)]"
              }
            }
            
            IMPORTANT RULES:
            1. Return ONLY valid JSON - no additional text before or after
            2. Provide exactly 4 options: 1 correct and 3 incorrect
            3. correctOptionIndex should be 1-based (1, 2, 3, or 4)
            4. All story content and options must be in \(wordLanguage) (the word's language)
            5. Only explanations should be in \(userLanguage) (the user's language)
            6. Incorrect options should be plausible but clearly wrong in \(wordLanguage)
            7. Each option should have a clear explanation in \(userLanguage)
            8. Story should be appropriate for language learning
            9. The correct word should be the best choice for the blank
            10. Use proper JSON escaping for quotes and special characters
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

    private func parseSentenceEvaluationResponse(_ response: String) throws -> AISentenceEvaluation {
        print("🔍 [OpenAIAPIService] Parsing sentence evaluation response...")

        let cleanedResponse = cleanJSONResponse(response)
        print("🔍 [OpenAIAPIService] Cleaned response: \(cleanedResponse)")

        let openAIResponse = try JSONDecoder().decode(
            OpenAISentenceEvaluationResponse.self,
            from: cleanedResponse.data(using: .utf8)!
        )

        let evaluation = AISentenceEvaluation(
            targetWord: openAIResponse.targetWord,
            sentence: openAIResponse.sentence,
            usageScore: openAIResponse.usageScore,
            grammarScore: openAIResponse.grammarScore,
            overallScore: openAIResponse.overallScore,
            feedback: openAIResponse.feedback,
            isCorrect: openAIResponse.isCorrect,
            suggestions: openAIResponse.suggestions
        )

        print("✅ [OpenAIAPIService] Successfully parsed sentence evaluation")
        return evaluation
    }

    private func parseContextQuestionResponse(_ response: String) throws -> AIContextQuestion {
        print("🔍 [OpenAIAPIService] Parsing context question response...")

        let cleanedResponse = cleanJSONResponse(response)
        print("🔍 [OpenAIAPIService] Cleaned response: \(cleanedResponse)")

        let openAIResponse = try JSONDecoder().decode(
            OpenAIContextQuestionResponse.self,
            from: cleanedResponse.data(using: .utf8)!
        )

        let options = openAIResponse.options.map { optionData in
            AIContextOption(
                text: optionData.text,
                isCorrect: optionData.isCorrect,
                explanation: optionData.explanation
            )
        }

        let contextQuestion = AIContextQuestion(
            word: openAIResponse.word,
            question: openAIResponse.question,
            options: options,
            correctOptionIndex: openAIResponse.correctOptionIndex,
            explanation: openAIResponse.explanation
        )

        print("✅ [OpenAIAPIService] Successfully parsed context question")
        return contextQuestion
    }

    private func parseFillInTheBlankStoryResponse(_ response: String) throws -> AIFillInTheBlankStory {
        print("🔍 [OpenAIAPIService] Parsing fill in the blank story response...")

        let cleanedResponse = cleanJSONResponse(response)
        print("🔍 [OpenAIAPIService] Cleaned response: \(cleanedResponse)")

        let openAIResponse = try JSONDecoder().decode(
            OpenAIFillInTheBlankStoryResponse.self,
            from: cleanedResponse.data(using: .utf8)!
        )

        let options = openAIResponse.options.map { optionData in
            AIFillInTheBlankOption(
                text: optionData.text,
                isCorrect: optionData.isCorrect,
                explanation: optionData.explanation
            )
        }

        let story = AIFillInTheBlankStory(
            word: openAIResponse.word,
            story: openAIResponse.story,
            options: options,
            correctOptionIndex: openAIResponse.correctOptionIndex,
            explanation: openAIResponse.explanation
        )

        print("✅ [OpenAIAPIService] Successfully parsed fill in the blank story")
        return story
    }

    // MARK: - New Batch Parsing Methods

    private func parseSentencesEvaluationResponse(_ response: String) throws -> [AISentenceEvaluation] {
        print("🔍 [OpenAIAPIService] Parsing sentences evaluation response...")

        let cleanedResponse = cleanJSONResponse(response)
        print("🔍 [OpenAIAPIService] Cleaned response: \(cleanedResponse)")

        let openAIResponse = try JSONDecoder().decode(
            OpenAISentencesEvaluationResponse.self,
            from: cleanedResponse.data(using: .utf8)!
        )

        let evaluations = openAIResponse.evaluations.map { evaluationData in
            AISentenceEvaluation(
                targetWord: evaluationData.targetWord,
                sentence: evaluationData.sentence,
                usageScore: evaluationData.usageScore,
                grammarScore: evaluationData.grammarScore,
                overallScore: evaluationData.overallScore,
                feedback: evaluationData.feedback,
                isCorrect: evaluationData.isCorrect,
                suggestions: evaluationData.suggestions
            )
        }

        print("✅ [OpenAIAPIService] Successfully parsed \(evaluations.count) sentence evaluations")
        return evaluations
    }

    private func parseContextQuestionsResponse(_ response: String) throws -> [AIContextQuestion] {
        print("🔍 [OpenAIAPIService] Parsing context questions response...")

        let cleanedResponse = cleanJSONResponse(response)
        print("🔍 [OpenAIAPIService] Cleaned response: \(cleanedResponse)")

        let openAIResponse = try JSONDecoder().decode(
            OpenAIContextQuestionsResponse.self,
            from: cleanedResponse.data(using: .utf8)!
        )

        let questions = openAIResponse.questions.map { questionData in
            let options = questionData.options.map { optionData in
                AIContextOption(
                    text: optionData.text,
                    isCorrect: optionData.isCorrect,
                    explanation: optionData.explanation
                )
            }

            return AIContextQuestion(
                word: questionData.word,
                question: questionData.question,
                options: options,
                correctOptionIndex: questionData.correctOptionIndex,
                explanation: questionData.explanation
            )
        }

        print("✅ [OpenAIAPIService] Successfully parsed \(questions.count) context questions")
        return questions
    }

    private func parseFillInTheBlankStoriesResponse(_ response: String) throws -> [AIFillInTheBlankStory] {
        print("🔍 [OpenAIAPIService] Parsing fill in the blank stories response...")

        let cleanedResponse = cleanJSONResponse(response)
        print("🔍 [OpenAIAPIService] Cleaned response: \(cleanedResponse)")

        let openAIResponse = try JSONDecoder().decode(
            OpenAIFillInTheBlankStoriesResponse.self,
            from: cleanedResponse.data(using: .utf8)!
        )

        let stories = openAIResponse.stories.map { storyData in
            let options = storyData.options.map { optionData in
                AIFillInTheBlankOption(
                    text: optionData.text,
                    isCorrect: optionData.isCorrect,
                    explanation: optionData.explanation
                )
            }

            return AIFillInTheBlankStory(
                word: storyData.word,
                story: storyData.story,
                options: options,
                correctOptionIndex: storyData.correctOptionIndex,
                explanation: storyData.explanation
            )
        }

        print("✅ [OpenAIAPIService] Successfully parsed \(stories.count) fill in the blank stories")
        return stories
    }

    private func parseSingleContextQuestionResponse(_ response: String) throws -> AIContextQuestion {
        print("🔍 [OpenAIAPIService] Parsing single context question response...")
        print("🔍 [OpenAIAPIService] Response: \(response)")

        let cleanedResponse = cleanJSONResponse(response)
        print("🔍 [OpenAIAPIService] Cleaned response: \(cleanedResponse)")

        let openAIResponse = try JSONDecoder().decode(
            OpenAISingleContextQuestionResponse.self,
            from: cleanedResponse.data(using: .utf8)!
        )

        let questionData = openAIResponse.question
        let options = questionData.options.map { optionData in
            AIContextOption(
                text: optionData.text,
                isCorrect: optionData.isCorrect,
                explanation: optionData.explanation
            )
        }

        let question = AIContextQuestion(
            word: questionData.word,
            question: questionData.question,
            options: options,
            correctOptionIndex: questionData.correctOptionIndex,
            explanation: questionData.explanation
        )

        print("✅ [OpenAIAPIService] Successfully parsed single context question")
        return question
    }

    private func parseSingleFillInTheBlankStoryResponse(_ response: String) throws -> AIFillInTheBlankStory {
        print("🔍 [OpenAIAPIService] Parsing single fill in the blank story response...")

        let cleanedResponse = cleanJSONResponse(response)
        print("🔍 [OpenAIAPIService] Cleaned response: \(cleanedResponse)")

        let openAIResponse = try JSONDecoder().decode(
            OpenAISingleFillInTheBlankStoryResponse.self,
            from: cleanedResponse.data(using: .utf8)!
        )

        let storyData = openAIResponse.story
        let options = storyData.options.map { optionData in
            AIFillInTheBlankOption(
                text: optionData.text,
                isCorrect: optionData.isCorrect,
                explanation: optionData.explanation
            )
        }

        let story = AIFillInTheBlankStory(
            word: storyData.word,
            story: storyData.story,
            options: options,
            correctOptionIndex: storyData.correctOptionIndex,
            explanation: storyData.explanation
        )

        print("✅ [OpenAIAPIService] Successfully parsed single fill in the blank story")
        return story
    }

    private func cleanJSONResponse(_ response: String) -> String {
        guard !response.isEmpty else { return response }

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

        // Try to fix common JSON issues
        do {
            // First, try to parse as-is
            _ = try JSONSerialization.jsonObject(with: cleaned.data(using: .utf8)!, options: [])
            return cleaned
        } catch {
            print("🔧 [OpenAIAPIService] JSON parsing failed, attempting to fix...")

            // Count braces and brackets to see if we're missing closing ones
            let openBraces = cleaned.components(separatedBy: "{").count - 1
            let closeBraces = cleaned.components(separatedBy: "}").count - 1
            let openBrackets = cleaned.components(separatedBy: "[").count - 1
            let closeBrackets = cleaned.components(separatedBy: "]").count - 1

            // Add missing closing braces
            if openBraces > closeBraces {
                let missingBraces = openBraces - closeBraces
                cleaned += String(repeating: "}", count: missingBraces)
            }

            // Add missing closing brackets
            if openBrackets > closeBrackets {
                let missingBrackets = openBrackets - closeBrackets
                cleaned += String(repeating: "]", count: missingBrackets)
            }

            // Try parsing again
            do {
                _ = try JSONSerialization.jsonObject(with: cleaned.data(using: .utf8)!, options: [])
                print("✅ [OpenAIAPIService] Successfully fixed JSON by adding missing braces/brackets")
                return cleaned
            } catch {
                print("🔧 [OpenAIAPIService] Still failed to parse JSON after fixing braces")

                // If still failing, try to extract the JSON part
                if let jsonStart = cleaned.firstIndex(of: "{") {
                    let jsonPart = String(cleaned[jsonStart...])
                    do {
                        _ = try JSONSerialization.jsonObject(with: jsonPart.data(using: .utf8)!, options: [])
                        print("✅ [OpenAIAPIService] Successfully extracted JSON part")
                        return jsonPart
                    } catch {
                        print("🔧 [OpenAIAPIService] Failed to extract valid JSON part")
                    }
                }

                // Return original if all attempts fail
                print("🔧 [OpenAIAPIService] Returning original response as fallback")
                return response
            }
        }
    }
}

#endif
