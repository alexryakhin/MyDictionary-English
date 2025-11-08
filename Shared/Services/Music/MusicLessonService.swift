//
//  MusicLessonService.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin
//

import Foundation
import FirebaseFirestore

/// Service for managing music lessons with Firestore caching
/// Public lessons cached in Firestore, personal adaptations in CoreData
final class MusicLessonService {
    
    static let shared = MusicLessonService()
    
    private let db = Firestore.firestore()
    private let aiService = AIService.shared
    private let coreDataService = CoreDataService.shared
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// Get lesson for a song, checking Firestore cache first
    /// Uses song's CEFR level, not user's CEFR level
    /// - Parameters:
    ///   - song: The song to get lesson for
    ///   - lyrics: The song lyrics
    /// - Returns: Lesson adapted to song's CEFR level
    func getLesson(for song: Song, lyrics: SongLyrics) async throws -> AdaptedLesson {
        guard let userProfile = OnboardingService.shared.userProfile,
              let firstStudyLanguage = userProfile.studyLanguages.first,
              let cefrLevel = song.cefrLevel else {
            throw MusicError.authenticationRequired
        }
        
        let targetLanguage = firstStudyLanguage.language

        // 1. Try to get cached lesson from Firestore (public/shared)
        if let cachedLesson = try? await getLessonFromFirestore(songId: song.id) {
            // 2. Adapt lesson (lessons are language-specific, no filtering by user level)
            let adapted = AdaptedLesson(
                songId: cachedLesson.songId,
                language: targetLanguage, // Use InputLanguage enum
                phrases: cachedLesson.phrases,
                grammarNuggets: cachedLesson.grammarNuggets,
                cultureNotes: cachedLesson.cultureNotes,
                quiz: generateQuizFromTemplate(cachedLesson.quizTemplate, level: cefrLevel),
                adaptedAt: Date(),
                userLevel: cefrLevel
            )
            
            // 3. Save personal adaptation to CoreData
            try? await savePersonalLesson(adapted, for: song.id, userLevel: cefrLevel)

            return adapted
        }
        
        // 4. Generate new lesson with AI if not in cache
        guard aiService.canMakeAIRequest() else {
            throw AIError.proRequired
        }

        guard let lyricsText = lyrics.plainLyrics?.nilIfEmpty else {
            throw AIError.invalidResponse
        }
        
        // Generate lesson with AI using song's CEFR level and plain lyrics
        let response: MusicDiscoveringResponse = try await aiService.request(.musicLesson(
            song: song,
            lyrics: lyricsText,
            targetLanguage: targetLanguage,
            cefrLevel: cefrLevel
        ))
        
        // 5. Convert to FirestoreLesson format
        let firestoreLesson = convertToFirestoreLesson(response, songId: song.id, language: targetLanguage.rawValue)
        
        // 6. Save to Firestore (public cache) - save after generation during listening
        let languagePath = targetLanguage.englishName.lowercased()
        try await saveLessonToFirestore(firestoreLesson, for: song.id, languagePath: languagePath)

        // 7. Create adapted lesson (lessons are language-specific)
        let adapted = AdaptedLesson(
            songId: firestoreLesson.songId,
            language: targetLanguage, // Use InputLanguage enum
            phrases: firestoreLesson.phrases,
            grammarNuggets: firestoreLesson.grammarNuggets,
            cultureNotes: firestoreLesson.cultureNotes,
            quiz: generateQuizFromTemplate(firestoreLesson.quizTemplate, level: cefrLevel),
            adaptedAt: Date(),
            userLevel: cefrLevel // Use CEFRLevel enum
        )
        
        // 8. Save personal adaptation to CoreData
        try await savePersonalLesson(adapted, for: song.id, userLevel: cefrLevel)

        return adapted
    }
    
    /// Get saved personal lesson from CoreData
    func getSavedLesson(for songId: String) async -> AdaptedLesson? {
        let context = coreDataService.context
        
        return await context.perform {
            let fetchRequest = CDMusicLesson.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "songId == %@", songId)
            fetchRequest.fetchLimit = 1
            
            guard let entity = try? context.fetch(fetchRequest).first,
                  let adaptedContent = entity.adaptedContent,
                  let lesson = try? JSONDecoder().decode(AdaptedLesson.self, from: adaptedContent) else {
                return nil
            }
            
            return lesson
        }
    }
    
    // MARK: - Private Methods
    
    /// Get lesson from Firestore cache (public/shared)
    private func getLessonFromFirestore(songId: String) async throws -> FirestoreLesson {
        guard let userProfile = OnboardingService.shared.userProfile,
              let firstStudyLanguage = userProfile.studyLanguages.first else {
            throw MusicError.authenticationRequired
        }
        
        let languagePath = firstStudyLanguage.language.englishName.lowercased()
        let docRef = db.collection("musicLessons")
            .document(languagePath)
            .collection("lessons")
            .document(songId)
        
        let document = try await docRef.getDocument()
        
        guard document.exists,
              let data = document.data() else {
            throw MusicError.lessonNotFound
        }
        
        // Convert Firestore data to FirestoreLesson
        let jsonData = try JSONSerialization.data(withJSONObject: data)
        let decoder = JSONDecoder()
        
        // Handle Firestore Timestamp conversion
        let lesson = try decoder.decode(FirestoreLesson.self, from: jsonData)
        return lesson
    }
    
    // Note: adaptLesson method removed - lessons are now language-specific and use song's CEFR level
    // No filtering by user level needed
    
    /// Generate quiz from template (randomized per session)
    private func generateQuizFromTemplate(_ template: QuizTemplate, level: CEFRLevel) -> AdaptedQuiz {
        // Randomly select fill-in-blank items (up to 5)
        let fillInItems = Array(template.fillInBlanks.shuffled().prefix(5))
        
        // Randomly select MCQ items (up to 5)
        let mcqItems = Array(template.meaningMCQ.shuffled().prefix(5))
        
        return AdaptedQuiz(
            fillInBlanks: fillInItems,
            meaningMCQ: mcqItems,
            generatedAt: Date()
        )
    }
    
    /// Save lesson to Firestore (public cache)
    /// Path: musicLessons/{language.englishName.lowercased()}/{songId}
    private func saveLessonToFirestore(_ lesson: FirestoreLesson, for songId: String, languagePath: String) async throws {
        let docRef = db.collection("musicLessons")
            .document(languagePath)
            .collection("lessons")
            .document(songId)
        
        // Convert to Firestore-compatible dictionary
        let encoder = JSONEncoder()
        let data = try encoder.encode(lesson)
        let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
        
        // Convert Date to Timestamp
        var firestoreDict = dict
        if let date = dict["generated_at"] as? Date {
            firestoreDict["generated_at"] = Timestamp(date: date)
        }
        
        try await docRef.setData(firestoreDict, merge: false)
    }
    
    /// Convert MusicDiscoveringResponse to FirestoreLesson
    private func convertToFirestoreLesson(_ response: MusicDiscoveringResponse, songId: String, language: String) -> FirestoreLesson {
        // Convert vocabulary words to phrases
        let phrases = response.vocabularyWords.map { vocab in
            LessonPhrase(
                text: vocab.word,
                meaning: vocab.definition,
                cefr: determineCEFRForWord(vocab),
                example: vocab.examples.first ?? "",
                audioPrompt: nil
            )
        }
        
        // Convert explanations to grammar nuggets (simplified)
        let grammarNuggets: [GrammarNugget] = [] // Will be enhanced by AI
        
        // Convert cultural context to culture notes
        let cultureNotes: [CultureNote]
        if let culturalContext = response.culturalContext {
            cultureNotes = [
                CultureNote(
                    text: culturalContext,
                    cefr: nil
                )
            ]
        } else {
            cultureNotes = []
        }

        // Convert quiz to template
        let quizTemplate = QuizTemplate(
            fillInBlanks: [],
            meaningMCQ: response.quiz?.questions.map { question in
                MCQItem(
                    question: question.question,
                    correctAnswer: question.options.first(where: { $0.isCorrect })?.text ?? "",
                    options: question.options.map { $0.text },
                    explanation: question.explanation
                )
            } ?? []
        )
        
        return FirestoreLesson(
            songId: songId,
            language: language,
            phrases: phrases,
            grammarNuggets: grammarNuggets,
            cultureNotes: cultureNotes,
            quizTemplate: quizTemplate,
            generatedBy: "gpt-4o-mini",
            generatedAt: Date(),
            version: 1
        )
    }
    
    /// Determine CEFR level for a word (simplified - can be enhanced)
    private func determineCEFRForWord(_ vocab: VocabularyWord) -> String {
        // Simple heuristic: common words are A1-A2, complex are B1+
        let wordLength = vocab.word.count
        let definitionLength = vocab.definition.count
        
        if wordLength < 5 && definitionLength < 50 {
            return "A1"
        } else if wordLength < 8 && definitionLength < 100 {
            return "A2"
        } else if definitionLength < 150 {
            return "B1"
        } else {
            return "B2"
        }
    }
    
    /// Save personal adapted lesson to CoreData
    private func savePersonalLesson(_ lesson: AdaptedLesson, for songId: String, userLevel: CEFRLevel) async throws {
        let context = coreDataService.context
        
        try await context.perform {
            let fetchRequest = CDMusicLesson.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "songId == %@", songId)
            fetchRequest.fetchLimit = 1
            
            let entity: CDMusicLesson
            if let existing = try context.fetch(fetchRequest).first {
                entity = existing
            } else {
                entity = CDMusicLesson(context: context)
                entity.id = UUID()
                entity.songId = songId
            }
            
            // Encode adapted lesson
            let encoder = JSONEncoder()
            entity.adaptedContent = try encoder.encode(lesson)
            entity.userLevel = userLevel.rawValue
            entity.savedAt = lesson.adaptedAt
            entity.lastAccessed = Date()
            
            try context.save()
        }
    }
    
    /// Generate pre-listen hook with AI and determine song's CEFR level
    /// Hook is cached locally (user-specific, locale-specific), not in Firestore
    /// Returns: (PreListenHook, CEFRLevel) - the hook and the determined song CEFR level
    func generatePreListenHook(for song: Song, lyrics: String, targetLanguage: InputLanguage) async throws -> (PreListenHook, CEFRLevel) {
        guard aiService.canMakeAIRequest() else {
            throw AIError.proRequired
        }

        // Use AI service to generate hook (determines song's CEFR level)
        // If languageToUse is nil, AI will detect language from lyrics
        let hook: PreListenHook = try await aiService.request(
            .musicPreListenHook(
                song: song,
                targetLanguage: targetLanguage
            )
        )

        return (hook, hook.songCEFRLevel)
    }
    
    /// Convert AdaptedLesson to MusicDiscoveringResponse for UI
    func convertToMusicDiscoveringResponse(_ lesson: AdaptedLesson, song: Song) -> MusicDiscoveringResponse {
        // Convert phrases to explanations
        let explanations = lesson.phrases.map { phrase in
            LyricExplanation(
                lyricLine: phrase.example,
                explanation: "\(phrase.text): \(phrase.meaning)",
                lineNumber: nil
            )
        }
        
        // Convert phrases to vocabulary words
        let vocabularyWords = lesson.phrases.map { phrase in
            VocabularyWord(
                word: phrase.text,
                definition: phrase.meaning,
                examples: [phrase.example],
                partOfSpeech: "phrase",
                context: phrase.example
            )
        }
        
        // Combine culture notes
        let culturalContext = lesson.cultureNotes.map { $0.text }.joined(separator: "\n\n")
        
        // Convert quiz to AIComprehensionQuiz
        let quiz = AIComprehensionQuiz(
            questions: lesson.quiz.meaningMCQ.map { mcq in
                AIComprehensionQuestion(
                    question: mcq.question,
                    options: mcq.options.map { option in
                        AIComprehensionOption(
                            text: option,
                            isCorrect: option == mcq.correctAnswer
                        )
                    },
                    explanation: mcq.explanation
                )
            },
            difficulty: lesson.userLevel.rawValue // Convert CEFRLevel to String
        )
        
        return MusicDiscoveringResponse(
            songInfo: SongInfo(
                title: song.title,
                artist: song.artist,
                album: song.album,
                language: lesson.language.englishName // Convert InputLanguage to String
            ),
            explanations: explanations,
            vocabularyWords: vocabularyWords,
            culturalContext: culturalContext.isEmpty ? nil : culturalContext,
            quiz: quiz.questions.isEmpty ? nil : quiz
        )
    }
}

// MARK: - Adapted Lesson Model

/// User's personalized lesson (stored in CoreData as encoded Data)
struct AdaptedLesson: Codable, Hashable {
    let songId: String
    let language: InputLanguage // Target language for the lesson
    let phrases: [LessonPhrase]
    let grammarNuggets: [GrammarNugget]
    let cultureNotes: [CultureNote]
    let quiz: AdaptedQuiz
    let adaptedAt: Date
    let userLevel: CEFRLevel // Song's CEFR level
}

struct AdaptedQuiz: Codable, Hashable {
    let fillInBlanks: [FillInBlankItem]
    let meaningMCQ: [MCQItem]
    let generatedAt: Date
}
