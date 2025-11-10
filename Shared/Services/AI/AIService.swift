//
//  AIService.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 1/27/25.
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
    private let authenticationService = AuthenticationService.shared
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    private init() {
        observeRemoteConfigReadiness()
    }

    // MARK: - Public API

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
        case .contextMultipleChoice, .fillInTheBlank, .sentenceWriting, .storyLab:
            return true
        case .spelling, .chooseDefinition:
            return false
        }
    }

    /// Gets all AI quiz types
    /// - Returns: Array of AI-powered quiz types
    func getAIQuizzes() -> [Quiz] {
        return [.contextMultipleChoice, .fillInTheBlank, .sentenceWriting, .storyLab]
    }

    // MARK: - Request Enum

    public enum Request {
        case wordInfo(word: String, maxDefinitions: Int, inputLanguage: InputLanguage)
        case sentences(sentences: [(sentence: String, targetWord: String)])
        case contextQuestion(word: String, wordLanguage: InputLanguage, partOfSpeech: String?)
        case fillBlank(word: String, wordLanguage: InputLanguage, meaning: String?, partOfSpeech: String?)
        case story(input: StoryInput)
        case paywall(userProfile: UserOnboardingProfile, userLanguage: InputLanguage)
        case musicPreListenHook(song: Song, targetLanguage: InputLanguage) // CEFR level is determined by AI
        case musicLesson(song: Song, lyrics: String, targetLanguage: InputLanguage, cefrLevel: CEFRLevel) // Plain lyrics (no timestamps)
        case musicRecommendations(language: InputLanguage, userProfile: UserOnboardingProfile) // AI generates 2 songs per CEFR level
    }

    // MARK: - Centralized Request Handler

    public func request<T: Codable & JSONSchemaConvertible>(_ r: Request) async throws -> T {
        // Validate network connectivity
        guard !reachabilityService.isOffline else {
            throw AIError.networkError
        }

        // Validate service initialization
        guard isInitialized else {
            throw AIError.notInitialized
        }

        // Validate Pro subscription (except for paywall)
        if case .paywall = r {
            // Paywall doesn't require Pro subscription
        } else {
            guard SubscriptionService.shared.isProUser else {
                throw AIError.proRequired
            }
        }

        isGenerating = true
        defer { isGenerating = false }

        // Build prompt based on request type
        let prompt = buildPrompt(for: r)

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

        guard let openAI = openAI else {
            throw AIError.notInitialized
        }

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

    // MARK: - Prompt Builder

    private func buildPrompt(for r: Request) -> String {
        switch r {
        case .wordInfo(let word, let maxDefinitions, let inputLanguage):
            let userLanguage = InputLanguage(rawValue: Locale.current.language.languageCode?.identifier ?? "en") ?? InputLanguage.english
            return buildWordInformationPrompt(
                word: word,
                maxDefinitions: maxDefinitions,
                inputLanguage: inputLanguage,
                userLanguage: userLanguage
            )

        case .sentences(let sentences):
            return buildSentencesEvaluationPrompt(
                sentences: sentences,
                userLanguage: getCurrentAppLanguage()
            )

        case .contextQuestion(let word, let wordLanguage, let partOfSpeech):
            return buildSingleContextQuestionPrompt(
                word: word,
                wordLanguage: wordLanguage,
                userLanguage: getCurrentAppLanguage(),
                partOfSpeech: partOfSpeech
            )

        case .fillBlank(let word, let wordLanguage, let meaning, let partOfSpeech):
            return buildSingleFillInTheBlankStoryPrompt(
                word: word,
                wordLanguage: wordLanguage,
                userLanguage: getCurrentAppLanguage(),
                meaning: meaning,
                partOfSpeech: partOfSpeech
            )

        case .story(let input):
            return buildStoryPrompt(input: input)

        case .paywall(let userProfile, let userLanguage):
            return buildPaywallPrompt(userProfile: userProfile, userLanguage: userLanguage)

        case .musicPreListenHook(let song, let targetLanguage):
            return buildMusicPreListenHookPrompt(
                song: song,
                targetLanguage: targetLanguage,
                userLanguage: getCurrentAppLanguage()
            )
        
        case .musicLesson(let song, let lyrics, let targetLanguage, let cefrLevel):
            return buildMusicLessonPrompt(
                song: song,
                lyrics: lyrics,
                targetLanguage: targetLanguage,
                songCEFR: cefrLevel,
                userLanguage: getCurrentAppLanguage()
            )
            
        case .musicRecommendations(let language, let userProfile):
            return buildMusicRecommendationsPrompt(
                language: language,
                userProfile: userProfile,
                userLanguage: getCurrentAppLanguage()
            )
        }
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
        You are **Maestro**, a world-class AI language teacher trained at top universities in Paris, Kyoto, Madrid, and beyond.
        
        **Core Belief**: Language and culture are inseparable. Teach vocabulary, grammar, and idioms *through real cultural moments* — food, festivals, etiquette, history, humor.
        
        Teach with clarity, warmth, and precision. Use the user’s interests to make every example vivid and memorable.
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
            
            Use this information to personalize your responses - provide accurate word descriptions and quizzes that would match with the user's interests.
            """
        }

        return systemPrompt
    }

    private func observeRemoteConfigReadiness() {
        if remoteConfigService.isReady {
            Task { @MainActor [weak self] in
                self?.initializeClient()
            }
        }
        
        remoteConfigService.readinessPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                guard let self else { return }
                Task { @MainActor in
                    self.initializeClient()
                }
            }
            .store(in: &cancellables)
    }
    
    @MainActor
    private func initializeClient() {
        guard let apiKey = remoteConfigService.getOpenAIAPIKey(), !apiKey.isEmpty else {
            openAI = nil
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

    private func formattedList(_ values: [String]) -> String {
        let cleaned = values
            .map { $0.trimmed }
            .filter { $0.isNotEmpty }
        
        return cleaned.nilIfEmpty?.joined(separator: ", ") ?? "Not specified"
    }


    private func getCurrentAppLanguage() -> InputLanguage {
        let currentLanguageCode = Locale.current.language.languageCode?.identifier ?? "en"
        return InputLanguage(rawValue: currentLanguageCode) ?? .english
    }

    // MARK: - Prompt Building Methods

    private func buildWordInformationPrompt(
        word: String,
        maxDefinitions: Int,
        inputLanguage: InputLanguage,
        userLanguage: InputLanguage
    ) -> String {
        return """
        IMPORTANT: This is for EDUCATIONAL PURPOSES in a language learning application. User's language is \(userLanguage.englishName), and he/she learns \(inputLanguage.englishName). Provide comprehensive information for the word/phrase '\(word)' in \(userLanguage.englishName) and examples in \(inputLanguage.englishName).
        
        IMPORTANT RULES:
        1. Definition must be in the \(userLanguage.englishName). Examples must be in \(inputLanguage.englishName) (the language of the input word).
        2. Part of speech should be chosen from available values.
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
        userLanguage: InputLanguage
    ) -> String {
        let sentencesList = sentences.enumerated().map { index, item in
            "\(index + 1). Target Word: '\(item.targetWord)' | Sentence: '\(item.sentence)'"
        }.joined(separator: "\n")

        return """
        IMPORTANT: This is for EDUCATIONAL PURPOSES in a language learning application. Evaluate the given sentences for correct usage of their target words.
        
        User Language: \(userLanguage.englishName)
        
        Sentences to evaluate:
        \(sentencesList)
        
        Evaluate each sentence and provide feedback in \(userLanguage.englishName).
        
        IMPORTANT RULES:
        1. Evaluate each sentence independently
        2. Usage score focuses on whether the word is used correctly in context
        3. Grammar score focuses on sentence structure and syntax
        4. Overall score should be a weighted average (usage 70%, grammar 30%)
        5. Feedback should be educational and constructive in \(userLanguage.englishName)
        6. isCorrect should be true if the word is used correctly (overall score >= 60)
        7. Suggestions should be specific and actionable in \(userLanguage.englishName)
        8. Be encouraging but honest about mistakes
        9. Consider context, meaning, and natural language usage
        10. All feedback and suggestions must be in \(userLanguage.englishName)
        """
    }

    private func buildSingleContextQuestionPrompt(
        word: String,
        wordLanguage: InputLanguage,
        userLanguage: InputLanguage,
        partOfSpeech: String? = nil
    ) -> String {
        var prompt = """
        IMPORTANT: This is for EDUCATIONAL PURPOSES in a language learning application. Create a multiple choice question to test understanding of word usage in context.
        
        Word Language: \(wordLanguage.englishName)
        User Language: \(userLanguage.englishName)
        
        Word to create question for: '\(word)' (in \(wordLanguage.englishName))
        """

        if let partOfSpeech = partOfSpeech, !partOfSpeech.isEmpty {
            prompt += "\nPart of Speech: \(partOfSpeech)"
        }

        prompt += """
        
        Create one question with 4 options.
        
        IMPORTANT RULES:
        1. Only ONE option should be correct
        2. All sentences must be in \(wordLanguage.englishName) (the word's language)
        3. Only explanations should be in \(userLanguage.englishName) (the user's language)
        4. Incorrect options should show common mistakes or wrong contexts in \(wordLanguage.englishName)
        5. Sentences should be natural and realistic in \(wordLanguage.englishName)
        6. Explanations should be educational and clear in \(userLanguage.englishName)
        7. Make the question challenging but fair
        8. Consider different meanings and contexts of the word in \(wordLanguage.englishName)
        9. Ensure the correct answer is clearly the best choice
        10. Use the word as a \(partOfSpeech ?? "word") in all sentences
        11. Question might include some context that is important
        """

        return prompt
    }

    private func buildSingleFillInTheBlankStoryPrompt(
        word: String,
        wordLanguage: InputLanguage,
        userLanguage: InputLanguage,
        meaning: String? = nil,
        partOfSpeech: String? = nil
    ) -> String {
        var prompt = """
        IMPORTANT: This is for EDUCATIONAL PURPOSES in a language learning application. Create a multiple-choice fill-in-the-blank story for vocabulary practice.
        
        Word Language: \(wordLanguage.englishName)
        User Language: \(userLanguage.englishName)
        
        Word to create story for: '\(word)' (in \(wordLanguage.englishName))
        """

        if let partOfSpeech = partOfSpeech, !partOfSpeech.isEmpty {
            prompt += "\nPart of Speech: \(partOfSpeech)"
        }

        if let meaning = meaning, !meaning.isEmpty {
            prompt += "\n\nSpecific meaning to focus on: '\(meaning)'"
        }

        prompt += """
        
        Create one story with 4 answer options.
        
        EXAMPLE FORMAT:
        - Story: "Juan no pudo venir a la fiesta ___ tenía que trabajar."
        - Options should be: "porque", "pero", "aunque", "sin embargo" (just the words, not the full sentence)
        
        IMPORTANT RULES:
        1. Provide exactly 4 options: 1 correct and 3 incorrect
        2. All story content and options must be in \(wordLanguage.englishName) (the word's language)
        3. Only explanations should be in \(userLanguage.englishName) (the user's language)
        4. Incorrect options should be plausible but clearly wrong in \(wordLanguage.englishName)
        5. Each option should have a clear explanation in \(userLanguage.englishName)
        6. Story should be appropriate for language learning
        7. The correct word should be the best choice for the blank
        8. Use the word as a \(partOfSpeech ?? "word") in the story - maintain proper grammatical usage
        9. Don't put blanks inside answers. Only the story can have it.
        10. CRITICAL: Each option's "text" field should contain ONLY the word/phrase that fills the blank, NOT the full sentence with the blank
        11. The story should contain the blank (use "___" to represent it), but the options should only contain the actual words that could fill that blank
        """

        return prompt
    }

    private func buildStoryPrompt(input: StoryInput) -> String {
        let userLanguage = getCurrentAppLanguage()
        let targetLanguageName = input.targetLanguage.englishName
        let cefrLevel = input.cefrLevel.rawValue

        var prompt = """
        IMPORTANT: This is for EDUCATIONAL PURPOSES in a language learning application. Create an engaging, coherent story with comprehension quizzes for language learning.
        
        Target Language: \(targetLanguageName) (\(input.targetLanguage.rawValue))
        User Language: \(userLanguage)
        CEFR Level: \(cefrLevel)
        Number of Pages: \(input.pageCount)
        
        """

        // Handle input words or custom text
        if let savedWords = input.savedWords, !savedWords.isEmpty {
            let wordsList = savedWords.joined(separator: ", ")
            prompt += """
            Words to incorporate naturally into the story:
            \(wordsList)
            
            These words should appear naturally in the narrative. Do not force them - they should fit the story context naturally.
            
            """
        } else if let customText = input.customText?.nilIfEmpty {
            prompt += """
            CUSTOM STORY INPUT: "\(customText)"
            - Use this custom text as the theme, inspiration, or starting point for the story
            - Maintain appropriate vocabulary and complexity for \(cefrLevel) level throughout
            - Ensure the story flows naturally across all \(input.pageCount) pages and builds upon the custom text theme/expression
            """
        }

        // Determine paragraph length based on CEFR level
        let paragraphLength: String
        switch input.cefrLevel {
        case .a1, .a2:
            paragraphLength = "100-200 words"
        case .b1, .b2:
            paragraphLength = "200-300 words"
        case .c1, .c2:
            paragraphLength = "300-400 words"
        }

        prompt += """
        STORY REQUIREMENTS:
        - Create a coherent, engaging story across \(input.pageCount) pages
        - Each page: ONE substantial paragraph (~\(paragraphLength))
        - Vocabulary and complexity: \(cefrLevel) level
        - All content must be in \(targetLanguageName)
        - Story must flow naturally between pages
        
        COMPREHENSION QUIZ (per page):
        - Create 3-5 questions per page (aim for 4)
        - Test understanding: main ideas, inference, context, cause/effect, vocabulary
        - Each question: 4 multiple-choice options
        - CRITICAL: Options must be ANSWERS (short phrases/words/statements), NOT other questions
          Example: "¿Quién juega?" → ["La niña", "El niño", "La mujer", "El hombre"]
          NOT: ["¿Quién juega?", "¿Qué come?", ...]
        - CRITICAL: Each option must have a "text" field (the answer text) and an "isCorrect" field (true for the correct answer, false for others)
        - CRITICAL: Exactly ONE option must have isCorrect: true - this option must be explicitly stated in or clearly inferable from the story text on that page
        - Each question must include a brief explanation (max 200 characters) of why the correct answer is right
        - Only ONE correct answer; incorrect options should be plausible but wrong
        - Questions in \(targetLanguageName), appropriate for \(cefrLevel) level
        
        OUTPUT JSON STRUCTURE (order matters):
        - Title: Short, engaging title
        - Pages: Array of page objects with the following fields IN THIS EXACT ORDER:
          1. pageNumber: Integer (page number, starting from 1)
          2. storyText: String (the story paragraph for this page) - MUST come before questions
          3. questions: Array of question objects
        - Metadata: CEFR level, target language, word count, vocabulary words
        
        CRITICAL: In each page object, storyText MUST come before questions in the JSON. The order is: pageNumber, storyText, questions.
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
    private func buildPaywallPrompt(
        userProfile: UserOnboardingProfile,
        userLanguage: InputLanguage
    ) -> String {
        return """
        Create a compelling, personalized paywall for a language learning app. Generate content in \(userLanguage.englishName) that:
        
        1. Creates a compelling title that addresses the user by name and highlights their primary learning goal
        2. Writes a subtitle that emphasizes the target language and learning benefits  
        3. Selects 4-7 SubscriptionFeature benefits that are most relevant to their user type, goals, and interests
        4. Writes SHORT, concise descriptions for each selected feature (maximum 3 lines, focus on key benefits)
        
        IMPORTANT: Keep feature descriptions brief and punchy. Each description should be 1-2 sentences maximum. Focus on the core benefit, not detailed explanations.
        """
    }
}

// MARK: - Music Discovering Content Generation

extension AIService {
    // MARK: - Prompt Building Methods

    private func buildMusicLessonPrompt(
        song: Song,
        lyrics: String,
        targetLanguage: InputLanguage,
        songCEFR: CEFRLevel,
        userLanguage: InputLanguage
    ) -> String {
        return """
        IMPORTANT: This is for EDUCATIONAL PURPOSES in a language learning application. Analyze a song to help a user learn \(targetLanguage.englishName).
        
        Song Information:
        - Title: "\(song.title)"
        - Artist: "\(song.artist)"
        - Album: "\(song.album ?? "Unknown")"
        
        Lyrics (plain text, no timestamps):
        \(lyrics)
        
        Target Language: \(targetLanguage.englishName) (\(targetLanguage.rawValue))
        Song CEFR Level: \(songCEFR.rawValue) (This is the song's difficulty level, not the user's level)
        
        CRITICAL: The lesson content must be fully in \(targetLanguage.englishName). If it's an English song, the entire lesson is in English. If it's a Spanish song, the entire lesson is in Spanish. No translations - the lesson language matches the song language.
        
        Generate comprehensive learning content that MUST include:
        
        1. EXPLANATIONS: Provide explanations for key concepts (5-10 explanations):
           - Focus on interesting vocabulary, idioms, or cultural references related to the song
           - Explain meaning, context, and cultural significance
           - Keep explanations appropriate for \(songCEFR.rawValue) level
           - All explanations in \(targetLanguage.englishName) (fully in the target language)
        
        2. VOCABULARY WORDS, IDIOMS, PHRASES, AND EXPRESSIONS:
           - Based on the song's title, artist, and cultural context, provide 10-15 important idioms, phrases, and expressions that would typically appear in this type of song
           - Provide clear meanings and explanations in \(targetLanguage.englishName) (fully in the target language)
           - Explain cultural and emotional interpretation (what it means beyond words)
           - Include everyday examples showing how learners can use these phrases naturally in conversation
           - Level-appropriate explanations for \(songCEFR.rawValue) level
           - For each word/phrase, include:
             * The original phrase in \(targetLanguage.englishName)
             * Meaning and explanation
             * Cultural/emotional meaning
             * 2-3 example sentences showing natural usage in conversation
             * Phonetics in IPA standard format
           - All content in \(targetLanguage.englishName)

        3. GRAMMAR NUGGETS:
           - Provide 3-5 grammar nugget items
           - Grammar nugget requirements:
             * Each Grammar nugget has a rule, example from the lyrics, and explanation ALL in \(targetLanguage.englishName)
             * Include a correct CEFR level for this particular grammar rule
        
        4. CULTURAL AND EMOTIONAL INTERPRETATION:
           - Explain what the song means beyond the literal words (based on title, artist, and cultural context)
           - Cultural themes or references in the song
           - Historical or social context if relevant
           - Emotional undertones and subtext
           - Why this song is culturally significant
           - Written in \(targetLanguage.englishName) (fully in the target language)
           - Appropriate for \(songCEFR.rawValue) level learners
        
        5. QUIZ:
           - Provide 5-8 multiple-choice comprehension question items
           - Comprehension Quiz requirements:
             * Each question has exactly 4 options
             * Exactly one option is correct
             * Include a concise explanation for the correct answer
           - Focus questions on idioms, phrases, vocabulary, or cultural context from this lesson
           - Write all questions, options, and explanations in \(targetLanguage.englishName)
        
        Remember: The output MUST always begin with a short Pre-Listen Hook or Context Summary. Focus on idioms, phrases, cultural interpretation, and practical usage examples. All content should be appropriate for \(songCEFR.rawValue) level learners and fully in \(targetLanguage.englishName).
        """
    }
    
    private func buildMusicPreListenHookPrompt(
        song: Song,
        targetLanguage: InputLanguage,
        userLanguage: InputLanguage
    ) -> String {
        let cefrInstruction: String
        if let knownLevel = song.cefrLevel {
            // Song already has a CEFR level, don't make AI determine it again
            cefrInstruction = """
            1. SONG_CEFR_LEVEL (REQUIRED): Use the already determined CEFR level: \(knownLevel.rawValue)
               - Do NOT analyze or change this level
               - Simply return: \(knownLevel.rawValue)
            """
        } else {
            // Song doesn't have a CEFR level, AI needs to determine it
            cefrInstruction = """
            1. SONG_CEFR_LEVEL (REQUIRED): Determine the song's CEFR level based on lyrics analysis:
               - Analyze vocabulary complexity
               - Consider grammar structures used
               - Assess overall difficulty
            """
        }
        
        return """
        IMPORTANT: This is for EDUCATIONAL PURPOSES in a language learning application. Create a pre-listen hook to prepare a learner for listening to a song.
        
        Song Information:
        - Title: "\(song.title)"
        - Artist: "\(song.artist)"
        
        Target Language: \(targetLanguage.englishName) (\(targetLanguage.rawValue))
        User Language: \(userLanguage.englishName)
        
        Create a pre-listen hook with the following components:
        
        \(cefrInstruction)
        
        2. HOOK: A brief, engaging introduction (30-50 words) that:
           - Captures the song's theme or mood
           - Highlights what the learner should focus on while listening
           - Sets expectations for vocabulary and grammar they'll encounter
           - Written in \(userLanguage.englishName)
        
        3. TARGET PHRASES: Exactly 3 key phrases to watch for:
           - Select phrases that are important for understanding the song
           - Include the original phrase in \(targetLanguage.englishName)
           - Include meaning about where/when it appears in the song in \(userLanguage.englishName)
           - Assign appropriate CEFR level for each phrase
        
        4. GRAMMAR HIGHLIGHT (optional): One grammar point to watch for:
           - Should be relevant to the song's lyrics
           - Brief explanation (1-2 sentences) in \(userLanguage.englishName)
        
        5. CULTURAL NOTE (optional): Brief cultural context:
           - Historical or social significance if relevant
           - Why this song matters culturally
           - Written in \(userLanguage.englishName)
        
        Make the hook engaging and motivating, helping the learner prepare for an enjoyable learning experience.
        """
    }
    
    private func buildMusicRecommendationsPrompt(
        language: InputLanguage,
        userProfile: UserOnboardingProfile,
        userLanguage: InputLanguage
    ) -> String {
        let studyLanguages = userProfile.studyLanguages.map { "\($0.language.englishName) (\($0.proficiencyLevel.rawValue))" }.joined(separator: ", ")
        let interests = userProfile.interests.map { $0.rawValue }.joined(separator: ", ")
        let ageGroup = userProfile.ageGroup.rawValue

        return """
        IMPORTANT: This is for EDUCATIONAL PURPOSES in a language learning application. Generate music recommendations for language learning.
        
        USER PROFILE:
        - Study Languages: \(studyLanguages)
        - Age Group: \(ageGroup)
        - Interests: \(interests)
        - Learning Goals: \(userProfile.learningGoals.map { $0.rawValue }.joined(separator: ", "))
        - Weekly Word Goal: \(userProfile.weeklyWordGoal) words
        
        TARGET LANGUAGE: \(language.englishName)
        
        TASK:
        Generate exactly 12 song recommendations (2 songs for each CEFR level) that are:
        - All in \(language.englishName) language
        - Have clear pronunciation and lyrics
        - Culturally relevant and popular
        - Appropriate for their assigned CEFR level
        
        For each song, provide:
        - Title: Song title
        - Artist: Artist name
        - Language: \(language.rawValue)
        - CEFR Level: Assign appropriate level (A1, A2, B1, B2, C1, or C2) based on vocabulary and grammar complexity
        - Reason: Why this song is good for its assigned CEFR level (1-2 sentences)
        
        Ensure diversity across genres while maintaining educational value for each proficiency level.
        """
    }
}
