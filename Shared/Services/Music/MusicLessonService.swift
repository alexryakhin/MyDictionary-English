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
              let cefrLevel = song.cefrLevel,
              let targetLanguage = lyrics.detectedLanguage else {
            throw MusicError.userProfileNotCompleted
        }

        // 1. Try to get cached lesson from Firestore (public/shared)
        if let cachedLesson = try? await getLessonFromFirestore(songId: song.id) {
            // 2. Adapt lesson (lessons are language-specific, no filtering by user level)
            let adapted = AdaptedLesson(
                songId: cachedLesson.songId,
                language: targetLanguage,
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
        let quizTemplate = try prepareQuizTemplate(
            for: response,
            song: song,
            lyrics: lyricsText
        )
        
        let firestoreLesson = convertToFirestoreLesson(
            response,
            songId: song.id,
            language: targetLanguage,
            cefr: cefrLevel,
            quizTemplateOverride: quizTemplate
        )
        
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
            throw MusicError.userProfileNotCompleted
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
        // Use all available fill-in-blank items (already limited when generated)
        let fillInItems = template.fillInBlanks.shuffled()
        
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
    private func convertToFirestoreLesson(
        _ response: MusicDiscoveringResponse,
        songId: String,
        language: InputLanguage,
        cefr: CEFRLevel,
        quizTemplateOverride: QuizTemplate? = nil
    ) -> FirestoreLesson {
        // Convert vocabulary words to phrases
        let phrases = response.vocabularyWords.map { vocab in
            LessonPhrase(
                text: vocab.word,
                meaning: vocab.definition,
                phonetics: vocab.phonetics,
                cefr: determineCEFRForWord(vocab),
                example: vocab.examples.first ?? "",
                partOfSpeech: vocab.partOfSpeech
            )
        }
        
        let grammarNuggets: [GrammarNugget] = response.grammarNuggets.map {
            GrammarNugget(
                rule: $0.rule,
                example: $0.example,
                explanation: $0.explanation,
                cefr: $0.cefr
            )
        }

        let quizTemplate = quizTemplateOverride ?? buildQuizTemplate(from: response.comprehensionQuestions, fillInItems: [])

        return FirestoreLesson(
            songId: songId,
            language: language,
            phrases: phrases,
            grammarNuggets: grammarNuggets,
            cultureNotes: response.culturalContext,
            quizTemplate: quizTemplate,
            generatedBy: "gpt-4o-mini",
            generatedAt: Date(),
            version: 1
        )
    }
    
    func prepareQuizTemplate(
        for response: MusicDiscoveringResponse,
        song: Song,
        lyrics: String
    ) throws -> QuizTemplate {
        do {
            try validateQuiz(
                comprehensionQuestions: response.comprehensionQuestions,
                song: song
            )

            let fillInItems = try generateFillInBlankItems(from: lyrics, song: song)

            let template = buildQuizTemplate(
                from: response.comprehensionQuestions,
                fillInItems: fillInItems
            )

            logSuccess("[MusicLessonService] Prepared quiz for '\(song.title)' (MCQ: \(template.meaningMCQ.count), Fill-in: \(template.fillInBlanks.count))")

            return template
        } catch {
            logWarning("[MusicLessonService] Falling back to on-device quiz generation for '\(song.title)': \(error.localizedDescription)")
            throw error
        }
    }
    
    private func validateQuiz(comprehensionQuestions: [AIComprehensionQuestion], song: Song) throws {
        if comprehensionQuestions.isEmpty {
            logError("[MusicLessonService] Quiz missing MCQ section for song '\(song.title)'")
            throw MusicError.invalidResponse
        }

        for (index, question) in comprehensionQuestions.enumerated() {
            if question.options.count != 4 {
                logError("[MusicLessonService] MCQ \(index + 1) for '\(song.title)' does not have 4 options (found \(question.options.count))")
                throw MusicError.invalidResponse
            }
            
            let correctCount = question.options.filter { $0.isCorrect }.count
            if correctCount != 1 {
                logError("[MusicLessonService] MCQ \(index + 1) for '\(song.title)' has \(correctCount) correct options (expected 1)")
                throw MusicError.invalidResponse
            }
        }
    }
    
    private func buildQuizTemplate(
        from comprehensionQuestions: [AIComprehensionQuestion],
        fillInItems: [FillInBlankItem]
    ) -> QuizTemplate {
        let meaningItems: [MCQItem] = comprehensionQuestions.enumerated().compactMap { index, question in
            guard let correct = question.options.first(where: { $0.isCorrect }) else {
                logWarning("[MusicLessonService] Missing correct option for MCQ at index \(index)")
                return nil
            }
            
            return MCQItem(
                question: question.question,
                correctAnswer: correct.text,
                options: question.options.map { $0.text },
                explanation: question.explanation
            )
        }
        
        return QuizTemplate(
            fillInBlanks: fillInItems,
            meaningMCQ: meaningItems
        )
    }
    
    private func buildFallbackMCQItems(from vocabulary: [MusicDiscoveringResponse.VocabularyWord]) -> [MCQItem] {
        let candidates = vocabulary.filter { !$0.definition.isEmpty }
        var items: [MCQItem] = []
        
        for word in candidates.shuffled() {
            var options: [String] = []
            appendUniqueOption(word.definition, to: &options)
            
            for candidate in candidates.shuffled() {
                guard candidate.word.caseInsensitiveCompare(word.word) != .orderedSame else { continue }
                appendUniqueOption(candidate.definition, to: &options)
                if options.count == 4 { break }
            }
            
            guard options.count == 4 else { continue }
            
            let shuffled = options.shuffled()
            items.append(
                MCQItem(
                    question: "What best matches \"\(word.word)\" in this song?",
                    correctAnswer: word.definition,
                    options: shuffled,
                    explanation: word.definition
                )
            )
            
            if items.count == 4 { break }
        }
        
        return items
    }
    
    private func generateFillInBlankItems(from lyrics: String, song: Song) throws -> [FillInBlankItem] {
        let rawLines = lyrics
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        var uniqueLines: [String] = []
        var seenLines = Set<String>()
        for line in rawLines {
            let key = line.lowercased()
            if !seenLines.contains(key) {
                uniqueLines.append(line)
                seenLines.insert(key)
            }
        }
        
        let globalWordPool = uniqueLines
            .flatMap { tokenizeWords(in: $0) }
        
        let uniqueWordPool = Dictionary(grouping: globalWordPool, by: { $0.normalized })
            .compactMap { $0.value.first }
            .filter { $0.original.count >= 3 }
        
        guard uniqueLines.count >= 5, uniqueWordPool.count >= 4 else {
            logError("[MusicLessonService] Not enough lyrics content to build fill-in blanks for '\(song.title)'")
            throw MusicError.invalidResponse
        }
        
        let maxQuestions = min(10, uniqueLines.count)
        let minQuestions = min(5, maxQuestions)
        guard minQuestions > 0 else {
            throw MusicError.invalidResponse
        }
        let questionRange = minQuestions == maxQuestions ? minQuestions...maxQuestions : minQuestions...maxQuestions
        let questionCount = questionRange.lowerBound == questionRange.upperBound ? questionRange.lowerBound : Int.random(in: questionRange)
        
        var generatedItems: [FillInBlankItem] = []
        let shuffledLines = uniqueLines.shuffled()
        
        for line in shuffledLines {
            guard generatedItems.count < questionCount else { break }
            let candidates = tokenizeWords(in: line)
            var uniqueCandidates: [WordCandidate] = []
            var seen = Set<String>()
            for candidate in candidates where candidate.original.count >= 3 {
                if seen.insert(candidate.normalized).inserted {
                    uniqueCandidates.append(candidate)
                }
            }
            guard let answer = uniqueCandidates.randomElement() else { continue }
            
            let distractorPool = uniqueWordPool.filter { $0.normalized != answer.normalized }
            guard distractorPool.count >= 3 else { continue }
            
            let distractors = Array(distractorPool.shuffled().prefix(3))
            guard distractors.count == 3 else { continue }
            
            var options = [answer.original] + distractors.map { $0.original }
            options.shuffle()
            
            let item = FillInBlankItem(
                lyricReference: line,
                blankWord: answer.original,
                options: options
            )
            generatedItems.append(item)
        }
        
        guard generatedItems.count >= minQuestions else {
            logError("[MusicLessonService] Generated only \(generatedItems.count) fill-in questions for '\(song.title)' (needs at least \(minQuestions))")
            throw MusicError.invalidResponse
        }
        
        return generatedItems
    }
    
    private func tokenizeWords(in line: String) -> [WordCandidate] {
        var tokens: [WordCandidate] = []
        var current = ""
        for character in line {
            if character.isLetter || character.isNumber || character == "'" {
                current.append(character)
            } else if !current.isEmpty {
                tokens.append(WordCandidate(original: current))
                current.removeAll(keepingCapacity: true)
            }
        }
        if !current.isEmpty {
            tokens.append(WordCandidate(original: current))
        }
        return tokens
    }
    
    private func appendUniqueOption(_ value: String, to array: inout [String]) {
        guard array.first(where: { $0.caseInsensitiveCompare(value) == .orderedSame }) == nil else { return }
        array.append(value)
    }
    
    /// Determine CEFR level for a word (simplified - can be enhanced)
    private func determineCEFRForWord(_ vocab: MusicDiscoveringResponse.VocabularyWord) -> CEFRLevel {
        // Simple heuristic: common words are A1-A2, complex are B1+
        let wordLength = vocab.word.count
        let definitionLength = vocab.definition.count
        
        if wordLength < 5 && definitionLength < 50 {
            return .a1
        } else if wordLength < 8 && definitionLength < 100 {
            return .a2
        } else if definitionLength < 150 {
            return .b1
        } else {
            return .b2
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
    func generatePreListenHook(for song: Song, lyrics: String, targetLanguage: InputLanguage) async throws -> PreListenHook {
        guard aiService.canMakeAIRequest() else {
            throw AIError.proRequired
        }

        // Use AI service to generate hook (determines song's CEFR level)
        // If languageToUse is nil, AI will detect language from lyrics
        return try await aiService.request(
            .musicPreListenHook(
                song: song,
                targetLanguage: targetLanguage
            )
        )
    }
}

private struct WordCandidate: Hashable {
    let original: String
    var normalized: String {
        original.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
    }
}
// MARK: - Adapted Lesson Model

/// User's personalized lesson (stored in CoreData as encoded Data)
struct AdaptedLesson: Codable, Hashable {
    let songId: String
    let language: InputLanguage // Target language for the lesson
    let phrases: [LessonPhrase]
    let grammarNuggets: [GrammarNugget]
    let cultureNotes: String
    let quiz: AdaptedQuiz
    let adaptedAt: Date
    let userLevel: CEFRLevel // Song's CEFR level
}

struct AdaptedQuiz: Codable, Hashable {
    let fillInBlanks: [FillInBlankItem]
    let meaningMCQ: [MCQItem]
    let generatedAt: Date
}
