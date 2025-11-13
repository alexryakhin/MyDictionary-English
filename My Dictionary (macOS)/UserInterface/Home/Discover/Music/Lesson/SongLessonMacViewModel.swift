//
//  SongLessonViewModel.swift
//  My Dictionary (macOS)
//
//  Created by Aleksandr Riakhin on 11/12/25.
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
        case addDiscoveredWords([String])
        case markExplanationRequested
        case updateSession(MusicDiscoveringSession)
        case saveSession
        case navigateToResults
        case playCultureNotes(String)
    }
    
    @Published private(set) var currentSession: MusicDiscoveringSession
    @Published private(set) var lesson: AdaptedLesson
    @Published private(set) var isTranslatingPhrases: Bool = false

    private let songLessonSessionService = SongLessonSessionService.shared
    private let song: Song
    private let translationService: TranslationService
    private let ttsPlayer = TTSPlayer.shared
    private var hasTranslatedPhrases = false
    private var lessonStartDate: Date?
    private var isLessonVisible = false
    var onResultsRequested: ((SongLessonConfig) -> Void)?

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
            title: Loc.MusicDiscovering.Lesson.Collection.title(song.title),
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

    func handle(_ input: Input) {
        switch input {
        case .submitQuizAnswer(let submission):
            submitQuizAnswer(submission)
        case .markQuizComplete:
            markQuizComplete()
        case .addDiscoveredWord(let word):
            addDiscoveredWord(word)
        case .addDiscoveredWords(let words):
            addDiscoveredWords(words)
        case .markExplanationRequested:
            markExplanationRequested()
        case .updateSession(let session):
            updateSession(session)
        case .saveSession:
            saveSession()
        case .navigateToResults:
            navigateToResults()
        case .playCultureNotes(let text):
            playCultureNotes(text)
        }
    }

    func lessonDidAppear() {
        isLessonVisible = true
        startTimingIfNeeded()
    }

    func lessonDidDisappear() {
        isLessonVisible = false
        accumulateListeningTime()
    }

    func handleScenePhaseChange(_ phase: ScenePhase) {
        switch phase {
        case .active:
            guard isLessonVisible else { return }
            startTimingIfNeeded()
        case .inactive, .background:
            guard isLessonVisible else { return }
            accumulateListeningTime()
        default:
            break
        }
    }
    
    @discardableResult
    func handleAsync(_ input: Input) -> Task<Void, Never>? {
        handle(input)
        return nil
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
                logWarning("[SongLessonMacViewModel] Failed to translate phrase '\(phrase.text)': \(error.localizedDescription)")
                translatedPhrases.append(phrase)
            }
        }
        
        lesson = AdaptedLesson(
            songId: lesson.songId,
            language: lesson.language,
            phrases: translatedPhrases,
            grammarNuggets: lesson.grammarNuggets,
            explanations: lesson.explanations,
            cultureNotes: lesson.cultureNotes,
            quiz: lesson.quiz,
            adaptedAt: lesson.adaptedAt,
            userLevel: lesson.userLevel
        )
        
        hasTranslatedPhrases = true
    }
    
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
    
    private func addDiscoveredWords(_ words: [String]) {
        guard words.isNotEmpty else { return }
        var session = currentSession
        for word in words {
            session.addDiscoveredWord(word)
        }
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
        isLessonVisible = false
        accumulateListeningTime()

        let config = SongLessonConfig(
            song: song,
            lesson: lesson,
            session: currentSession
        )
        if let onResultsRequested {
            onResultsRequested(config)
        } else {
            if SideBarManager.shared.selectedTab == .discover {
                SideBarManager.shared.discoverDetail = .music(.lessonResults(session: config.session, song: config.song))
            } else {
                SideBarManager.shared.selectedTab = .discover
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
                    SideBarManager.shared.discoverDetail = .music(.lessonResults(session: config.session, song: config.song))
                    self?.dismissPublisher.send()
                }
            }
        }
    }
    
    private func playCultureNotes(_ text: String) {
        guard !text.isEmpty else { return }
        
        if ttsPlayer.isPlaying {
            ttsPlayer.stop()
        }
        
        Task {
            do {
                try await ttsPlayer.play(text)
            } catch {
                logError("Failed to play culture notes: \(error.localizedDescription)")
            }
        }
    }

    private func startTimingIfNeeded() {
        guard lessonStartDate == nil else { return }
        lessonStartDate = Date()
    }

    private func accumulateListeningTime() {
        guard let start = lessonStartDate else { return }
        let elapsed = Date().timeIntervalSince(start)
        lessonStartDate = nil
        guard elapsed > 0 else { return }
        var session = currentSession
        session.addListeningTime(elapsed)
        currentSession = session
        saveSession()
    }
}
