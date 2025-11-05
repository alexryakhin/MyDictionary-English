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
    /// - Parameters:
    ///   - song: The song to get lesson for
    ///   - lyrics: The song lyrics
    ///   - userLevel: User's CEFR level for personalization
    /// - Returns: Adapted lesson for the user's level
    func getLesson(for song: Song, lyrics: SongLyrics, userLevel: CEFRLevel) async throws -> AdaptedLesson {
        // 1. Try to get cached lesson from Firestore (public/shared)
        if let cachedLesson = try? await getLessonFromFirestore(songId: song.id) {
            // 2. Adapt to user's CEFR level on-device
            let adapted = adaptLesson(cachedLesson, to: userLevel)
            
            // 3. Save personal adaptation to CoreData
            try? await savePersonalLesson(adapted, for: song.id, userLevel: userLevel)
            
            return adapted
        }
        
        // 4. Generate new lesson with AI if not in cache
        guard aiService.canMakeAIRequest() else {
            throw AIError.proRequired
        }
        
        guard let userProfile = OnboardingService.shared.userProfile,
              let firstStudyLanguage = userProfile.studyLanguages.first else {
            throw MusicError.authenticationRequired
        }
        
        let targetLanguage = firstStudyLanguage.language
        let lyricsText = lyrics.bestLyrics ?? lyrics.plainLyrics ?? ""
        
        guard !lyricsText.isEmpty else {
            throw AIError.invalidResponse
        }
        
        // Generate lesson with AI
        let response: MusicDiscoveringResponse = try await aiService.request(.musicContent(
            song: song,
            targetLanguage: targetLanguage,
            cefrLevel: userLevel
        ))
        
        // 5. Convert to FirestoreLesson format
        let firestoreLesson = convertToFirestoreLesson(response, songId: song.id, language: targetLanguage.rawValue)
        
        // 6. Save to Firestore (public cache)
        try await saveLessonToFirestore(firestoreLesson, for: song.id)
        
        // 7. Update song metadata
        let lyricsHash = lyrics.bestLyrics?.hash.description ?? lyrics.plainLyrics?.hash.description ?? ""
        try await updateSongMetadata(song, lyricsHash: lyricsHash)
        
        // 8. Adapt to user's CEFR level
        let adapted = adaptLesson(firestoreLesson, to: userLevel)
        
        // 9. Save personal adaptation to CoreData
        try await savePersonalLesson(adapted, for: song.id, userLevel: userLevel)
        
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
        let docRef = db.collection("lessons").document(songId)
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
    
    /// Adapt lesson to user's CEFR level (on-device, no AI needed)
    func adaptLesson(_ lesson: FirestoreLesson, to level: CEFRLevel) -> AdaptedLesson {
        let userLevelInt = level.level
        
        // Filter phrases by CEFR level (show up to user's level + 1)
        let filteredPhrases = lesson.phrases.filter { phrase in
            guard let phraseLevel = CEFRLevel(rawValue: phrase.cefr) else { return false }
            return phraseLevel.level <= userLevelInt + 1
        }
        
        // Filter grammar nuggets by CEFR level
        let filteredGrammar = lesson.grammarNuggets.filter { nugget in
            guard let nuggetLevel = nugget.cefr.flatMap({ CEFRLevel(rawValue: $0) }) else { return true }
            return nuggetLevel.level <= userLevelInt + 1
        }
        
        // Filter culture notes by CEFR level
        let filteredCulture = lesson.cultureNotes.filter { note in
            guard let noteLevel = note.cefr.flatMap({ CEFRLevel(rawValue: $0) }) else { return true }
            return noteLevel.level <= userLevelInt + 1
        }
        
        // Generate quiz from template (randomize for user)
        let quiz = generateQuizFromTemplate(lesson.quizTemplate, level: level)
        
        return AdaptedLesson(
            songId: lesson.songId,
            language: lesson.language,
            phrases: filteredPhrases,
            grammarNuggets: filteredGrammar,
            cultureNotes: filteredCulture,
            quiz: quiz,
            adaptedAt: Date(),
            userLevel: level.rawValue
        )
    }
    
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
    private func saveLessonToFirestore(_ lesson: FirestoreLesson, for songId: String) async throws {
        let docRef = db.collection("lessons").document(songId)
        
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
    
    /// Update song metadata in Firestore
    private func updateSongMetadata(_ song: Song, lyricsHash: String) async throws {
        let docRef = db.collection("songs").document(song.id)
        
        // Check if document exists
        let document = try await docRef.getDocument()
        
        if document.exists {
            // Increment generation count
            try await docRef.updateData([
                "generation_count": FieldValue.increment(Int64(1))
            ])
        } else {
            // Create new song document
            let songData: [String: Any] = [
                "id": song.id,
                "title": song.title,
                "artist": song.artist,
                "duration": song.duration,
                "language": "", // Will be set by tagging service
                "cefr_base": "",
                "difficulty_score": 0.0,
                "themes": [],
                "grammar_tags": [],
                "embedding": [],
                "lyrics_hash": lyricsHash,
                "generated_at": Timestamp(date: Date()),
                "generation_count": 1
            ]
            
            try await docRef.setData(songData)
        }
    }
    
    /// Convert MusicDiscoveringResponse to FirestoreLesson
    private func convertToFirestoreLesson(_ response: MusicDiscoveringResponse, songId: String, language: String) -> FirestoreLesson {
        // Convert vocabulary words to phrases
        let phrases = response.vocabularyWords.map { vocab in
            LessonPhrase(
                text: vocab.word,
                translation: vocab.definition,
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
    
    /// Generate pre-listen hook with AI (optional, can be cached)
    func generatePreListenHook(for song: Song, lyrics: String, userLevel: CEFRLevel) async throws -> PreListenHook {
        guard aiService.canMakeAIRequest() else {
            throw AIError.proRequired
        }
        
        guard let userProfile = OnboardingService.shared.userProfile,
              let firstStudyLanguage = userProfile.studyLanguages.first else {
            throw MusicError.authenticationRequired
        }
        
        let targetLanguage = firstStudyLanguage.language
        
        // Use AI service to generate hook
        let hook: PreListenHook = try await aiService.request(
            .musicPreListenHook(
                song: song,
                targetLanguage: targetLanguage,
                cefrLevel: userLevel
            )
        )
        
        return hook
    }
    
    /// Convert AdaptedLesson to MusicDiscoveringResponse for UI
    func convertToMusicDiscoveringResponse(_ lesson: AdaptedLesson, song: Song) -> MusicDiscoveringResponse {
        // Convert phrases to explanations
        let explanations = lesson.phrases.map { phrase in
            LyricExplanation(
                lyricLine: phrase.example,
                explanation: "\(phrase.text): \(phrase.translation)",
                lineNumber: nil
            )
        }
        
        // Convert phrases to vocabulary words
        let vocabularyWords = lesson.phrases.map { phrase in
            VocabularyWord(
                word: phrase.text,
                definition: phrase.translation,
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
            difficulty: lesson.userLevel
        )
        
        return MusicDiscoveringResponse(
            songInfo: SongInfo(
                title: song.title,
                artist: song.artist,
                album: song.album,
                language: lesson.language
            ),
            explanations: explanations,
            vocabularyWords: vocabularyWords,
            culturalContext: culturalContext.isEmpty ? nil : culturalContext,
            quiz: quiz.questions.isEmpty ? nil : quiz
        )
    }
}

// MARK: - Adapted Lesson Model

/// User's personalized lesson (stored in CoreData)
struct AdaptedLesson: Codable {
    let songId: String
    let language: String
    let phrases: [LessonPhrase]
    let grammarNuggets: [GrammarNugget]
    let cultureNotes: [CultureNote]
    let quiz: AdaptedQuiz
    let adaptedAt: Date
    let userLevel: String
}

struct AdaptedQuiz: Codable {
    let fillInBlanks: [FillInBlankItem]
    let meaningMCQ: [MCQItem]
    let generatedAt: Date
}
