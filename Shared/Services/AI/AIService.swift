//
//  AIService.swift
//  My Dictionary
//
//  Created by AI Assistant on 1/27/25.
//

import Foundation
import OpenAI
import Combine
import FirebaseAuth

// MARK: - AI Error Types

enum AIError: LocalizedError {
    case notInitialized
    case proRequired
    case featureDisabled
    case invalidResponse
    case apiError(String)
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .notInitialized:
            return Loc.Ai.AiError.notInitialized
        case .proRequired:
            return Loc.Ai.AiError.proRequired
        case .featureDisabled:
            return Loc.Ai.AiError.featureDisabled
        case .invalidResponse:
            return Loc.Ai.AiError.invalidResponse
        case .apiError(let message):
            return Loc.Ai.AiError.apiError(message)
        case .networkError:
            return Loc.Ai.AiError.networkError
        }
    }
}

// MARK: - AI Service

final class AIService: ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = AIService()
    
    // MARK: - Published Properties
    
    @Published var isInitialized = false
    @Published var isGenerating = false
    
    // MARK: - Private Properties
    
    private var openAI: OpenAI?
    private let remoteConfigService = RemoteConfigService.shared
    private let reachabilityService = ReachabilityService.shared
    private let onboardingService = OnboardingService.shared
    
    // MARK: - Initialization
    
    private init() {
        initializeClient()
    }
    
    // MARK: - Public Methods
    
    func generateWordInformation(
        for word: String,
        maxDefinitions: Int = 5,
        inputLanguage: InputLanguage
    ) async throws -> AIWordResponse {
        guard reachabilityService.isOffline == false else {
            throw AIError.networkError
        }
        
        do {
            // Check if AI service is initialized
            guard isInitialized else {
                throw AIError.notInitialized
            }
            
            // Check if user has Pro subscription
            guard SubscriptionService.shared.isProUser else {
                throw AIError.proRequired
            }

            let response = try await makeAIRequest(
                prompt: buildWordInformationPrompt(
                    word: word,
                    maxDefinitions: maxDefinitions,
                    inputLanguage: inputLanguage.englishName,
                    userLanguage: getCurrentAppLanguage()
                ),
                responseType: AIWordResponse.self
            )
            
            return response
        } catch {
            throw error
        }
    }
    
    func evaluateSentences(
        sentences: [(sentence: String, targetWord: String)]
    ) async throws -> [AISentenceEvaluation] {
        guard reachabilityService.isOffline == false else {
            throw AIError.networkError
        }

        do {
            // Check if AI service is initialized
            guard isInitialized else {
                throw AIError.notInitialized
            }
            
            // Check if user has Pro subscription
            guard SubscriptionService.shared.isProUser else {
                throw AIError.proRequired
            }

            let response = try await makeAIRequest(
                prompt: buildSentencesEvaluationPrompt(
                    sentences: sentences,
                    userLanguage: getCurrentAppLanguage()
                ),
                responseType: AISentenceEvaluations.self
            )

            return response.sentences
        } catch {
            throw error
        }
    }

    func generateSingleContextQuestion(
        word: String,
        wordLanguage: String,
        partOfSpeech: String? = nil
    ) async throws -> AIContextQuestion {
        guard reachabilityService.isOffline == false else {
            throw AIError.networkError
        }

        do {
            // Check if AI service is initialized
            guard isInitialized else {
                throw AIError.notInitialized
            }
            
            // Check if user has Pro subscription
            guard SubscriptionService.shared.isProUser else {
                throw AIError.proRequired
            }

            let response = try await makeAIRequest(
                prompt: buildSingleContextQuestionPrompt(
                    word: word,
                    wordLanguage: wordLanguage,
                    userLanguage: getCurrentAppLanguage(),
                    partOfSpeech: partOfSpeech
                ),
                responseType: AIContextQuestion.self
            )

            return response
        } catch {
            throw error
        }
    }
    
    func generateSingleFillInTheBlankStory(
        word: String,
        wordLanguage: String,
        meaning: String? = nil,
        partOfSpeech: String? = nil
    ) async throws -> AIFillInTheBlankStory {
        guard reachabilityService.isOffline == false else {
            throw AIError.networkError
        }

        do {
            // Check if AI service is initialized
            guard isInitialized else {
                throw AIError.notInitialized
            }
            
            // Check if user has Pro subscription
            guard SubscriptionService.shared.isProUser else {
                throw AIError.proRequired
            }

            let response = try await makeAIRequest(
                prompt: buildSingleFillInTheBlankStoryPrompt(
                    word: word,
                    wordLanguage: wordLanguage,
                    userLanguage: getCurrentAppLanguage(),
                    meaning: meaning,
                    partOfSpeech: partOfSpeech
                ),
                responseType: AIFillInTheBlankStory.self
            )

            return response
        } catch {
            throw error
        }
    }

    func canMakeAIRequest() -> Bool {
        return isInitialized && SubscriptionService.shared.isProUser
    }
    
    // MARK: - Quiz Access Control
    
    /// Checks if the user can run a specific AI quiz (premium only)
    /// - Parameter quizType: The type of quiz to check
    /// - Returns: true if user can run the quiz, false otherwise
    func canRunQuizToday(_ quizType: Quiz) -> Bool {
        return isInitialized && SubscriptionService.shared.isProUser && isAIQuiz(quizType)
    }

    /// Checks if a specific quiz type uses AI
    /// - Parameter quizType: The quiz type to check
    /// - Returns: true if the quiz uses AI, false otherwise
    func isAIQuiz(_ quizType: Quiz) -> Bool {
        switch quizType {
        case .contextMultipleChoice, .fillInTheBlank, .sentenceWriting:
            return true
        case .spelling, .chooseDefinition:
            return false
        }
    }
    
    /// Gets all AI quiz types
    /// - Returns: Array of AI-powered quiz types
    func getAIQuizzes() -> [Quiz] {
        return [.contextMultipleChoice, .fillInTheBlank, .sentenceWriting]
    }

    // MARK: - Private Methods
    
    /// Gets user profile context for AI personalization
    private func getUserProfileContext() -> AIUserProfileContext? {
        guard let profile = onboardingService.userProfile else { return nil }
        return AIUserProfileContext(from: profile)
    }
    
    /// Builds system prompt with user profile context
    private func buildSystemPrompt() -> String {
        var systemPrompt = """
        You are an AI assistant for a language learning application. 
        Provide educational content that helps users learn and understand language concepts.
        """
        
        // Add user profile context if available
        if let userProfile = getUserProfileContext() {
            systemPrompt += """
            
            USER PROFILE CONTEXT:
            - Name: \(userProfile.userName)
            - User Type: \(userProfile.userType)
            - Age Group: \(userProfile.ageGroup)
            - Learning Goals: \(userProfile.learningGoals.joined(separator: ", "))
            - Study Languages: \(userProfile.studyLanguages.joined(separator: ", "))
            - Interests: \(userProfile.interests.joined(separator: ", "))
            - Weekly Word Goal: \(userProfile.weeklyWordGoal) words
            - Preferred Study Time: \(userProfile.preferredStudyTime)
            
            Use this information to personalize your responses and make them more relevant to the user's learning goals and preferences.
            """
        }
        
        return systemPrompt
    }
    
    private func initializeClient() {
        let apiKey = remoteConfigService.getOpenAIAPIKey()
        
        guard !apiKey.isEmpty else {
            debugPrint("⚠️ OpenAI API key not configured")
            isInitialized = false
            return
        }
        
        let configuration = OpenAI.Configuration(
            token: apiKey,
            timeoutInterval: 60.0
        )
        openAI = OpenAI(configuration: configuration)
        isInitialized = true
        
        debugPrint("✅ AI service initialized")
    }
    
    private func makeAIRequest<T: Codable & JSONSchemaConvertible>(
        prompt: String,
        responseType: T.Type
    ) async throws -> T {
        guard isInitialized else {
            throw AIError.notInitialized
        }

        guard let openAI = openAI else {
            throw AIError.notInitialized
        }
        
        isGenerating = true
        defer { isGenerating = false }
        
        // Create system prompt with user profile context
        let systemPrompt = buildSystemPrompt()
        
        // Create chat query with structured output
        let query = ChatQuery(
            messages: [
                .system(.init(content: .textContent(systemPrompt))),
                .user(.init(content: .string(prompt)))
            ],
            model: .gpt4_o_mini,
            responseFormat: .jsonSchema(.init(
                name: String(describing: T.self),
                description: "AI-generated response",
                schema: .derivedJsonSchema(T.self),
                strict: true
            ))
        )
        
        let result = try await openAI.chats(query: query)
        
        // Validate response
        guard let jsonString = result.choices.first?.message.content,
              let jsonData = jsonString.data(using: String.Encoding.utf8) else {
            throw AIError.invalidResponse
        }
        
        // Parse response
        let response = try JSONDecoder().decode(T.self, from: jsonData)
        
        // Log usage
        if let usage = result.usage {
            debugPrint("📊 OpenAI tokens used: \(usage.totalTokens) (prompt: \(usage.promptTokens), completion: \(usage.completionTokens))")
        }
        
        return response
    }
    
    
    private func getCurrentAppLanguage() -> String {
        let currentLanguageCode = Locale.current.language.languageCode?.identifier ?? "en"
        return Locale(identifier: "en_US").localizedString(forLanguageCode: currentLanguageCode) ?? "English"
    }
    
    // MARK: - Prompt Building Methods
    
    private func buildWordInformationPrompt(
        word: String,
        maxDefinitions: Int,
        inputLanguage: String,
        userLanguage: String
    ) -> String {
        return """
        IMPORTANT: This is for EDUCATIONAL PURPOSES in a language learning application. User's language is \(userLanguage), and he/she learns \(inputLanguage). Provide comprehensive information for the word/phrase '\(word)' in \(userLanguage) and examples in \(inputLanguage).
        
        IMPORTANT RULES:
        1. Definition must be in the \(userLanguage). Examples must be in \(inputLanguage) (the language of the input word).
        2. Part of speech should be chosen from: 'noun', 'verb', 'adjective', 'adverb', 'conjunction', 'pronoun', 'preposition', 'exclamation', 'interjection', 'idiom', 'phrase', 'unknown'.
        3. Pronunciation should be of the original input word using International Phonetic Alphabet
        4. Focus on COMMON, EVERYDAY meanings and uses first, not just religious or specialized meanings
        5. Include different meanings and contexts - avoid repetitive definitions that mean the same thing
        6. For phrases and expressions, include both literal and figurative meanings
        7. Include idiomatic uses, slang, and colloquial expressions when applicable
        8. Keep definitions concise (1-3 sentences) and examples practical (1-2 sentences each)
        9. Provide up to \(maxDefinitions) distinct definitions
        10. Each definition should have 1-3 examples
        11. If the word/phrase has multiple distinct meanings, prioritize the most commonly used ones in everyday language
        12. For religious names/phrases, also include their use as exclamations, expressions of surprise, or in casual speech
        13. Include both formal and informal usage contexts
        14. As this is for educational purposes, include ALL meanings including slang, profanity, and informal expressions when they exist
        15. Provide accurate linguistic information regardless of content sensitivity - this helps language learners understand real-world usage
        16. CRITICAL: Definitions should NOT mention the input word itself - they should explain the concept without using the word being defined (this is essential for quiz functionality), but examples should include the word so a student will see a real usage.
        17. Don't provide duplicate definitions that basically mean the same thing but in different words.
        """
    }
    
    private func buildSentencesEvaluationPrompt(
        sentences: [(sentence: String, targetWord: String)],
        userLanguage: String
    ) -> String {
        let sentencesList = sentences.enumerated().map { index, item in
            "\(index + 1). Target Word: '\(item.targetWord)' | Sentence: '\(item.sentence)'"
        }.joined(separator: "\n")

        return """
        IMPORTANT: This is for EDUCATIONAL PURPOSES in a language learning application. Evaluate the given sentences for correct usage of their target words.
        
        User Language: \(userLanguage)
        
        Sentences to evaluate:
        \(sentencesList)
        
        Evaluate each sentence and provide feedback in \(userLanguage).
        
        IMPORTANT RULES:
        1. Evaluate each sentence independently
        2. Usage score focuses on whether the word is used correctly in context
        3. Grammar score focuses on sentence structure and syntax
        4. Overall score should be a weighted average (usage 70%, grammar 30%)
        5. Feedback should be educational and constructive in \(userLanguage)
        6. isCorrect should be true if the word is used correctly (overall score >= 60)
        7. Suggestions should be specific and actionable in \(userLanguage)
        8. Be encouraging but honest about mistakes
        9. Consider context, meaning, and natural language usage
        10. All feedback and suggestions must be in \(userLanguage)
        """
    }
    
    private func buildSingleContextQuestionPrompt(
        word: String,
        wordLanguage: String,
        userLanguage: String,
        partOfSpeech: String? = nil
    ) -> String {
        var prompt = """
        IMPORTANT: This is for EDUCATIONAL PURPOSES in a language learning application. Create a multiple choice question to test understanding of word usage in context.
        
        Word Language: \(wordLanguage)
        User Language: \(userLanguage)
        
        Word to create question for: '\(word)' (in \(wordLanguage))
        """
        
        if let partOfSpeech = partOfSpeech, !partOfSpeech.isEmpty {
            prompt += "\nPart of Speech: \(partOfSpeech)"
        }
        
        prompt += """
        
        Create one question with 4 options.
        
        IMPORTANT RULES:
        1. Only ONE option should be correct
        2. All sentences must be in \(wordLanguage) (the word's language)
        3. Only explanations should be in \(userLanguage) (the user's language)
        4. Incorrect options should show common mistakes or wrong contexts in \(wordLanguage)
        5. Sentences should be natural and realistic in \(wordLanguage)
        6. Explanations should be educational and clear in \(userLanguage)
        7. Make the question challenging but fair
        8. Consider different meanings and contexts of the word in \(wordLanguage)
        9. Ensure the correct answer is clearly the best choice
        10. Use the word as a \(partOfSpeech ?? "word") in all sentences - maintain proper grammatical usage
        """
        
        return prompt
    }
    
    private func buildSingleFillInTheBlankStoryPrompt(
        word: String,
        wordLanguage: String,
        userLanguage: String,
        meaning: String? = nil,
        partOfSpeech: String? = nil
    ) -> String {
        var prompt = """
        IMPORTANT: This is for EDUCATIONAL PURPOSES in a language learning application. Create a multiple-choice fill-in-the-blank story for vocabulary practice.
        
        Word Language: \(wordLanguage)
        User Language: \(userLanguage)
        
        Word to create story for: '\(word)' (in \(wordLanguage))
        """
        
        if let partOfSpeech = partOfSpeech, !partOfSpeech.isEmpty {
            prompt += "\nPart of Speech: \(partOfSpeech)"
        }
        
        if let meaning = meaning, !meaning.isEmpty {
            prompt += "\n\nSpecific meaning to focus on: '\(meaning)'"
        }
        
        prompt += """
        
        Create one story with 4 answer options.
        
        IMPORTANT RULES:
        1. Provide exactly 4 options: 1 correct and 3 incorrect
        2. All story content and options must be in \(wordLanguage) (the word's language)
        3. Only explanations should be in \(userLanguage) (the user's language)
        4. Incorrect options should be plausible but clearly wrong in \(wordLanguage)
        5. Each option should have a clear explanation in \(userLanguage)
        6. Story should be appropriate for language learning
        7. The correct word should be the best choice for the blank
        8. Use the word as a \(partOfSpeech ?? "word") in the story - maintain proper grammatical usage
        9. Don't put blanks inside answers. Only the story can have it.
        """
        
        return prompt
    }
}

// MARK: - AI Response Extensions

extension AIWordResponse {
    func toWordDefinitions() -> [WordDefinition] {
        return definitions.map { aiDefinition in
            return WordDefinition(
                partOfSpeech: aiDefinition.partOfSpeech,
                text: aiDefinition.definition,
                examples: aiDefinition.examples
            )
        }
    }
}

// MARK: - Paywall Content Generation

extension AIService {
    /// Generates personalized paywall content based on user profile
    /// Note: This method does NOT check for Pro subscription as non-subscribers need to see the paywall
    func generatePaywallContent(userProfile: UserOnboardingProfile, userLanguage: String) async throws -> AIPaywallContent {
        // Check if AI service is initialized (but not Pro status)
        guard isInitialized else {
            throw AIError.notInitialized
        }
        
        let prompt = buildPaywallPrompt(userProfile: userProfile, userLanguage: userLanguage)
        return try await makeAIRequest(prompt: prompt, responseType: AIPaywallContent.self)
    }
    
    private func buildPaywallPrompt(userProfile: UserOnboardingProfile, userLanguage: String) -> String {
        return """
        Create a compelling, personalized paywall for a language learning app. Generate content in \(userLanguage) that:

        1. Creates a compelling title that addresses the user by name and highlights their primary learning goal
        2. Writes a subtitle that emphasizes the target language and learning benefits  
        3. Selects 3-5 SubscriptionFeature benefits that are most relevant to their user type, goals, and interests
        4. Writes SHORT, concise descriptions for each selected feature (maximum 3 lines, focus on key benefits)

        Available SubscriptionFeature options: aiDefinitions, aiQuizzes, images, wordCollections, premiumTTS, unlimitedExport, createSharedDictionaries, tagManagement, advancedAnalytics, prioritySupport

        IMPORTANT: Keep feature descriptions brief and punchy. Each description should be 1-2 sentences maximum. Focus on the core benefit, not detailed explanations.
        """
    }
}
