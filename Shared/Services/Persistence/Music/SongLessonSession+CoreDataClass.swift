//
//  SongLessonSession+CoreDataClass.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin
//

import Foundation
import CoreData

@objc(CDSongLessonSession)
public class CDSongLessonSession: NSManagedObject {
    
    // MARK: - Computed Properties
    
    var song: Song? {
        get {
            guard let songData = songData else { return nil }
            return try? JSONDecoder().decode(Song.self, from: songData)
        }
        set {
            songData = try? JSONEncoder().encode(newValue)
            songId = newValue?.id
        }
    }
    
    var lesson: AdaptedLesson? {
        get {
            guard let lessonData = lessonData else { return nil }
            return try? JSONDecoder().decode(AdaptedLesson.self, from: lessonData)
        }
        set {
            lessonData = try? JSONEncoder().encode(newValue)
            if let lesson = newValue {
                targetLanguage = lesson.language.rawValue // Convert InputLanguage to String
                totalQuestions = Int32((lesson.quiz.fillInBlanks.count + lesson.quiz.meaningMCQ.count))
            }
        }
    }
    
    var session: MusicDiscoveringSession? {
        get {
            guard let sessionData = sessionData else { return nil }
            return try? JSONDecoder().decode(MusicDiscoveringSession.self, from: sessionData)
        }
        set {
            sessionData = try? JSONEncoder().encode(newValue)
            if let session = newValue {
                applySessionMetadata(from: session)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    func toMusicDiscoveringSession() -> MusicDiscoveringSession? {
        guard let session = session,
              let song = song else { return nil }
        return MusicDiscoveringSession(
            id: session.id,
            song: song,
            listeningProgress: session.listeningProgress,
            totalListeningTime: session.totalListeningTime,
            quizAnswers: session.quizAnswers,
            discoveredWords: session.discoveredWords,
            hasRequestedExplanation: session.hasRequestedExplanation,
            hasCompletedQuiz: session.hasCompletedQuiz,
            startedAt: session.startedAt,
            lastPlayedAt: session.lastPlayedAt
        )
    }
    
    func updateFromSession(_ session: MusicDiscoveringSession) {
        // Update session data
        sessionData = try? JSONEncoder().encode(session)
        applySessionMetadata(from: session)
    }
    
    private func applySessionMetadata(from session: MusicDiscoveringSession) {
        let song = song ?? session.song

        if songId == nil {
            songId = song.id
        }
        
        // Update completion status
        isComplete = session.hasCompletedQuiz
        
        // Update score
        score = Int32(session.quizScore)
        
        // Calculate correct answers
        correctAnswers = Int32(session.quizAnswers.filter { $0.isCorrect }.count)
        
        // Update last accessed
        lastAccessed = session.lastPlayedAt
    }
}

