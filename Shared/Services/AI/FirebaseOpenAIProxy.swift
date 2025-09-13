import Foundation

// MARK: - Firebase OpenAI Proxy Service

final class FirebaseOpenAIProxy: AIAPIServiceInterface {

    // MARK: - Properties

    private let cloudFunctionsService = CloudFunctionsService.shared

    // MARK: - Initialization

    init() {
        print("🔧 [FirebaseOpenAIProxy] Initialized for RELEASE mode")
        print("🔧 [FirebaseOpenAIProxy] Using Firebase Cloud Functions proxy")
    }

    // MARK: - Methods

    func generateWordInformation(
        for word: String,
        maxDefinitions: Int = 10,
        inputLanguage: InputLanguage,
        userLanguage: String,
        userId: String
    ) async throws -> AIWordResponse {
        print("🔍 [FirebaseOpenAIProxy] generateWordInformation called for word: '\(word)'")
        print("🔍 [FirebaseOpenAIProxy] Max definitions: \(maxDefinitions)")
        print("🔍 [FirebaseOpenAIProxy] User ID: \(userId)")
        print("🔍 [FirebaseOpenAIProxy] User language: \(userLanguage)")

        do {
            let response = try await cloudFunctionsService.openAIProxy(
                word: word,
                maxDefinitions: maxDefinitions,
                inputLanguage: inputLanguage.englishName,
                userLanguage: userLanguage
            )
            
            print("✅ [FirebaseOpenAIProxy] Received response from cloud functions")
            
            let wordInfo = try parseWordInformationResponse(response.data)
            print("✅ [FirebaseOpenAIProxy] Parsed response with \(wordInfo.definitions.count) definitions")
            
            return wordInfo
        } catch {
            print("❌ [FirebaseOpenAIProxy] Failed to generate word information: \(error.localizedDescription)")
            throw error
        }
    }
    
    func evaluateSentences(
        sentences: [(sentence: String, targetWord: String)],
        userId: String,
        userLanguage: String
    ) async throws -> [AISentenceEvaluation] {
        print("🔍 [FirebaseOpenAIProxy] evaluateSentences called for \(sentences.count) sentences")
        print("🔍 [FirebaseOpenAIProxy] User ID: \(userId)")

        do {
            let response = try await cloudFunctionsService.openAIProxy(
                word: sentences.first?.targetWord ?? "",
                maxDefinitions: 1,
                inputLanguage: InputLanguage.english.englishName,
                userLanguage: userLanguage,
                sentences: sentences
            )
            
            print("✅ [FirebaseOpenAIProxy] Received response for sentences evaluation")
            
            let evaluations = try parseSentencesEvaluationResponse(response.data)
            print("✅ [FirebaseOpenAIProxy] Parsed \(evaluations.count) sentence evaluations")
            
            return evaluations
        } catch {
            print("❌ [FirebaseOpenAIProxy] Failed to evaluate sentences: \(error.localizedDescription)")
            throw error
        }
    }
    
    func generateSingleContextQuestion(
        word: String,
        wordLanguage: String,
        userId: String,
        userLanguage: String
    ) async throws -> AIContextQuestion {
        print("🔍 [FirebaseOpenAIProxy] generateSingleContextQuestion called for word: '\(word)' in language: '\(wordLanguage)'")
        print("🔍 [FirebaseOpenAIProxy] User ID: \(userId)")

        do {
            let response = try await cloudFunctionsService.openAIProxy(
                word: word,
                maxDefinitions: 1,
                inputLanguage: InputLanguage.english.englishName,
                userLanguage: userLanguage,
                singleContextQuestion: true,
                wordLanguage: wordLanguage
            )
            
            print("✅ [FirebaseOpenAIProxy] Received response for single context question")
            
            let question = try parseSingleContextQuestionResponse(response.data)
            print("✅ [FirebaseOpenAIProxy] Parsed single context question")
            
            return question
        } catch {
            print("❌ [FirebaseOpenAIProxy] Failed to generate single context question: \(error.localizedDescription)")
            throw error
        }
    }
    
    func generateSingleFillInTheBlankStory(
        word: String,
        wordLanguage: String,
        userId: String,
        userLanguage: String
    ) async throws -> AIFillInTheBlankStory {
        print("🔍 [FirebaseOpenAIProxy] generateSingleFillInTheBlankStory called for word: '\(word)' in language: '\(wordLanguage)'")
        print("🔍 [FirebaseOpenAIProxy] User ID: \(userId)")

        do {
            let response = try await cloudFunctionsService.openAIProxy(
                word: word,
                maxDefinitions: 1,
                inputLanguage: InputLanguage.english.englishName,
                userLanguage: userLanguage,
                singleFillInTheBlank: true,
                wordLanguage: wordLanguage
            )
            
            print("✅ [FirebaseOpenAIProxy] Received response for single fill in the blank story")
            
            let story = try parseSingleFillInTheBlankStoryResponse(response.data)
            print("✅ [FirebaseOpenAIProxy] Parsed single fill in the blank story")
            
            return story
        } catch {
            print("❌ [FirebaseOpenAIProxy] Failed to generate single fill in the blank story: \(error.localizedDescription)")
            throw error
        }
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
            print("🔧 [FirebaseOpenAIProxy] JSON parsing failed, attempting to fix...")
            
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
                print("✅ [FirebaseOpenAIProxy] Successfully fixed JSON by adding missing braces/brackets")
                return cleaned
            } catch {
                print("🔧 [FirebaseOpenAIProxy] Still failed to parse JSON after fixing braces")
                
                // If still failing, try to extract the JSON part
                if let jsonStart = cleaned.firstIndex(of: "{") {
                    let jsonPart = String(cleaned[jsonStart...])
                    do {
                        _ = try JSONSerialization.jsonObject(with: jsonPart.data(using: .utf8)!, options: [])
                        print("✅ [FirebaseOpenAIProxy] Successfully extracted JSON part")
                        return jsonPart
                    } catch {
                        print("🔧 [FirebaseOpenAIProxy] Failed to extract valid JSON part")
                    }
                }
                
                // Return original if all attempts fail
                print("🔧 [FirebaseOpenAIProxy] Returning original response as fallback")
                return response
            }
        }
    }
    
    private func parseSentenceEvaluationResponse(_ response: String) throws -> AISentenceEvaluation {
        print("🔍 [FirebaseOpenAIProxy] Parsing sentence evaluation response...")
        
        let cleanedResponse = cleanJSONResponse(response)
        
        let openAIResponse = try JSONDecoder().decode(
            OpenAISentenceEvaluationResponse.self,
            from: cleanedResponse.data(using: .utf8)!
        )
        
        return AISentenceEvaluation(
            targetWord: openAIResponse.targetWord,
            sentence: openAIResponse.sentence,
            usageScore: openAIResponse.usageScore,
            grammarScore: openAIResponse.grammarScore,
            overallScore: openAIResponse.overallScore,
            feedback: openAIResponse.feedback,
            isCorrect: openAIResponse.isCorrect,
            suggestions: openAIResponse.suggestions
        )
    }
    
    private func parseContextQuestionResponse(_ response: String) throws -> AIContextQuestion {
        print("🔍 [FirebaseOpenAIProxy] Parsing context question response...")
        
        let cleanedResponse = cleanJSONResponse(response)
        
        let openAIResponse = try JSONDecoder().decode(
            OpenAIContextQuestionResponse.self,
            from: cleanedResponse.data(using: .utf8)!
        )
        
        return AIContextQuestion(
            word: openAIResponse.word,
            question: openAIResponse.question,
            options: openAIResponse.options.map { optionData in
                AIContextOption(
                    text: optionData.text,
                    isCorrect: optionData.isCorrect,
                    explanation: optionData.explanation
                )
            },
            correctOptionIndex: openAIResponse.correctOptionIndex,
            explanation: openAIResponse.explanation
        )
    }
    
    private func parseFillInTheBlankStoryResponse(_ response: String) throws -> AIFillInTheBlankStory {
        print("🔍 [FirebaseOpenAIProxy] Parsing fill-in-the-blank story response...")
        
        let cleanedResponse = cleanJSONResponse(response)
        
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
        
        return AIFillInTheBlankStory(
            word: openAIResponse.word,
            story: openAIResponse.story,
            options: options,
            correctOptionIndex: openAIResponse.correctOptionIndex,
            explanation: openAIResponse.explanation
        )
    }
    
    // MARK: - New Batch Parsing Methods
    
    private func parseSentencesEvaluationResponse(_ response: String) throws -> [AISentenceEvaluation] {
        print("🔍 [FirebaseOpenAIProxy] Parsing sentences evaluation response...")
        
        let cleanedResponse = cleanJSONResponse(response)
        
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
        
        return evaluations
    }
    
    private func parseContextQuestionsResponse(_ response: String) throws -> [AIContextQuestion] {
        print("🔍 [FirebaseOpenAIProxy] Parsing context questions response...")
        
        let cleanedResponse = cleanJSONResponse(response)
        
        let openAIResponse = try JSONDecoder().decode(
            OpenAIContextQuestionsResponse.self,
            from: cleanedResponse.data(using: .utf8)!
        )
        
        let questions = openAIResponse.questions.map { questionData in
            AIContextQuestion(
                word: questionData.word,
                question: questionData.question,
                options: questionData.options.map { optionData in
                    AIContextOption(
                        text: optionData.text,
                        isCorrect: optionData.isCorrect,
                        explanation: optionData.explanation
                    )
                },
                correctOptionIndex: questionData.correctOptionIndex,
                explanation: questionData.explanation
            )
        }
        
        return questions
    }
    
    private func parseFillInTheBlankStoriesResponse(_ response: String) throws -> [AIFillInTheBlankStory] {
        print("🔍 [FirebaseOpenAIProxy] Parsing fill-in-the-blank stories response...")
        
        let cleanedResponse = cleanJSONResponse(response)
        
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
        
        return stories
    }
    
    private func parseSingleContextQuestionResponse(_ response: String) throws -> AIContextQuestion {
        print("🔍 [FirebaseOpenAIProxy] Parsing single context question response...")
        print("🔍 [FirebaseOpenAIProxy] Response: \(response)")

        let cleanedResponse = cleanJSONResponse(response)
        
        let openAIResponse = try JSONDecoder().decode(
            OpenAISingleContextQuestionResponse.self,
            from: cleanedResponse.data(using: .utf8)!
        )
        
        let questionData = openAIResponse.question
        let question = AIContextQuestion(
            word: questionData.word,
            question: questionData.question,
            options: questionData.options.map { optionData in
                AIContextOption(
                    text: optionData.text,
                    isCorrect: optionData.isCorrect,
                    explanation: optionData.explanation
                )
            },
            correctOptionIndex: questionData.correctOptionIndex,
            explanation: questionData.explanation
        )
        
        return question
    }
    
    private func parseSingleFillInTheBlankStoryResponse(_ response: String) throws -> AIFillInTheBlankStory {
        print("🔍 [FirebaseOpenAIProxy] Parsing single fill-in-the-blank story response...")
        
        let cleanedResponse = cleanJSONResponse(response)
        
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
        
        return story
    }
}
