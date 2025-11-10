//
//  SongLessonViewModel.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin
//

import Foundation
import Combine
import SwiftUI

@MainActor
final class SongLessonViewModel: BaseViewModel {
    
    enum Input {
        case submitQuizAnswer(SongLesson.QuizSubmission)
        case markQuizComplete
        case addDiscoveredWord(String)
        case markExplanationRequested
        case updateSession(MusicDiscoveringSession)
        case saveSession
        case navigateToResults
    }
    
    @Published private(set) var currentSession: MusicDiscoveringSession
    @Published private(set) var lesson: AdaptedLesson
    @Published private(set) var isTranslatingPhrases: Bool = false
    @Published var shouldNavigateToResults: Bool = false
    
    private let songLessonSessionService = SongLessonSessionService.shared
    private let song: Song
    private let translationService: TranslationService
    private var hasTranslatedPhrases = false

    init(
        song: Song,
        lesson: AdaptedLesson,
        session: MusicDiscoveringSession,
        translationService: TranslationService = GoogleTranslateService.shared
    ) {
        self.song = song
        self.lesson = lesson
        self.currentSession = session
        self.translationService = translationService
        super.init()
        
        Task {
            do {
                try await songLessonSessionService.saveOrUpdateSession(
                    session,
                    lesson: lesson,
                    song: song
                )
            } catch {
                logError("Failed to persist initial session: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Computed Helpers
    
    var phraseItems: [WordCollectionItem] {
        lesson.phrases.enumerated().map { index, phrase in
            WordCollectionItem(
                id: "\(index)-\(phrase.text)",
                text: phrase.text,
                phonetics: phrase.phonetics,
                partOfSpeech: phrase.partOfSpeech,
                definition: phrase.meaning,
                examples: phrase.example.nilIfEmpty.map { [$0] } ?? []
            )
        }
    }
    
    var phraseWordCollection: WordCollection {
        WordCollection(
            title: "\(song.title) — Key Phrases",
            words: phraseItems,
            level: lesson.userLevel,
            tagValue: lesson.language.englishName,
            languageCode: lesson.language.rawValue,
            description: nil,
            imageUrl: nil,
            localImageName: nil,
            isPremium: false,
            isFeatured: false
        )
    }
    
    var canTranslatePhrases: Bool {
        guard !hasTranslatedPhrases else { return false }
        return Locale.current.language.languageCode?.identifier.lowercased() != lesson.language.rawValue.lowercased()
    }

    // MARK: - Input Handler
    
    func handle(_ input: Input) {
        switch input {
        case .submitQuizAnswer(let submission):
            submitQuizAnswer(submission)
        case .markQuizComplete:
            markQuizComplete()
        case .addDiscoveredWord(let word):
            addDiscoveredWord(word)
        case .markExplanationRequested:
            markExplanationRequested()
        case .updateSession(let session):
            updateSession(session)
        case .saveSession:
            saveSession()
        case .navigateToResults:
            navigateToResults()
        }
    }
    
    @discardableResult
    func handleAsync(_ input: Input) -> Task<Void, Never>? {
        switch input {
        default:
            handle(input)
            return nil
        }
    }
    
    func translatePhrases() async {
        guard canTranslatePhrases else { return }
        guard !isTranslatingPhrases else { return }
        isTranslatingPhrases = true
        defer { isTranslatingPhrases = false }
        
        let sourceLanguage = lesson.language.rawValue
        let targetLanguage = Locale.current.language.languageCode?.identifier ?? "en"
        var translatedPhrases: [LessonPhrase] = []
        translatedPhrases.reserveCapacity(lesson.phrases.count)
        
        for phrase in lesson.phrases {
            do {
                let translatedMeaning = try await translationService.translateDefinition(
                    phrase.meaning,
                    from: sourceLanguage,
                    to: targetLanguage
                )
                translatedPhrases.append(
                    LessonPhrase(
                        text: phrase.text,
                        meaning: translatedMeaning,
                        phonetics: phrase.phonetics,
                        cefr: phrase.cefr,
                        example: phrase.example,
                        partOfSpeech: phrase.partOfSpeech
                    )
                )
            } catch {
                logWarning("[SongLessonViewModel] Failed to translate phrase '\(phrase.text)': \(error.localizedDescription)")
                translatedPhrases.append(phrase)
            }
        }
        
        lesson = AdaptedLesson(
            songId: lesson.songId,
            language: lesson.language,
            phrases: translatedPhrases,
            grammarNuggets: lesson.grammarNuggets,
            cultureNotes: lesson.cultureNotes,
            quiz: lesson.quiz,
            adaptedAt: lesson.adaptedAt,
            userLevel: lesson.userLevel
        )
        
        hasTranslatedPhrases = true
    }
    
    // MARK: - Private Methods
    
    private func submitQuizAnswer(_ submission: SongLesson.QuizSubmission) {
        var session = currentSession
        session.submitQuizAnswer(submission)
        currentSession = session
        saveSession()
    }
    
    private func markQuizComplete() {
        var session = currentSession
        session.markQuizComplete()
        currentSession = session
        saveSession()
    }
    
    private func addDiscoveredWord(_ word: String) {
        var session = currentSession
        session.addDiscoveredWord(word)
        currentSession = session
        saveSession()
    }
    
    private func markExplanationRequested() {
        var session = currentSession
        session.markExplanationRequested()
        currentSession = session
        saveSession()
    }
    
    private func updateSession(_ session: MusicDiscoveringSession) {
        currentSession = session
        saveSession()
    }
    
    private func saveSession() {
        Task {
            do {
                try await songLessonSessionService.saveOrUpdateSession(
                    currentSession,
                    lesson: lesson,
                    song: song
                )
            } catch {
                logError("Failed to save session: \(error.localizedDescription)")
            }
        }
    }
    
    private func navigateToResults() {
        shouldNavigateToResults = true
    }
}

