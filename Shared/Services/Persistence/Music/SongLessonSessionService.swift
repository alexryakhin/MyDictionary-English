//
//  SongLessonSessionService.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin
//

import Foundation
import CoreData
import Combine

extension Notification.Name {
    static let songSessionDidChange = Notification.Name("songSessionDidChange")
}

final class SongLessonSessionService {
    
    static let shared = SongLessonSessionService()
    
    private let coreDataService = CoreDataService.shared
    
    private init() {}
    
    // MARK: - Save Session
    
    func saveOrUpdateSession(_ session: MusicDiscoveringSession, lesson: AdaptedLesson, song: Song) async throws {
        let context = coreDataService.context
        var thrownError: Error?
        
        context.performAndWait {
            do {
                let fetchRequest: NSFetchRequest<CDSongLessonSession> = CDSongLessonSession.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "songId == %@", song.id)
                fetchRequest.fetchLimit = 1
                
                if let existingSession = try context.fetch(fetchRequest).first {
                    existingSession.updateFromSession(session)
                    existingSession.lesson = lesson
                    existingSession.song = song
                    existingSession.lastAccessed = Date()
                } else {
                    let cdSession = CDSongLessonSession(context: context)
                    cdSession.id = session.id
                    cdSession.date = Date()
                    cdSession.lastAccessed = Date()
                    cdSession.song = song
                    cdSession.lesson = lesson
                    cdSession.session = session
                    cdSession.isComplete = session.hasCompletedQuiz
                    cdSession.totalQuestions = Int32((lesson.quiz.fillInBlanks.count + lesson.quiz.meaningMCQ.count))
                }
                
                if context.hasChanges {
                    try context.save()
                }
            } catch {
                thrownError = error
            }
        }
        
        if let error = thrownError {
            throw error
        }
        
        NotificationCenter.default.post(name: .songSessionDidChange, object: nil)
    }
    
    // MARK: - Load Sessions
    
    func getAllSessions() -> [CDSongLessonSession] {
        let fetchRequest: NSFetchRequest<CDSongLessonSession> = CDSongLessonSession.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \CDSongLessonSession.date, ascending: false)]
        
        do {
            return try coreDataService.context.fetch(fetchRequest)
        } catch {
            print("Error fetching song lesson sessions: \(error)")
            return []
        }
    }
    
    func getIncompleteSessions() -> [CDSongLessonSession] {
        let fetchRequest: NSFetchRequest<CDSongLessonSession> = CDSongLessonSession.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "isComplete == NO")
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \CDSongLessonSession.date, ascending: false)]
        
        do {
            return try coreDataService.context.fetch(fetchRequest)
        } catch {
            print("Error fetching incomplete song lesson sessions: \(error)")
            return []
        }
    }
    
    func getCompletedSessions() -> [CDSongLessonSession] {
        let fetchRequest: NSFetchRequest<CDSongLessonSession> = CDSongLessonSession.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "isComplete == YES")
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \CDSongLessonSession.date, ascending: false)]
        
        do {
            return try coreDataService.context.fetch(fetchRequest)
        } catch {
            print("Error fetching completed song lesson sessions: \(error)")
            return []
        }
    }
    
    func getFavoriteSongs() -> [CDSongLessonSession] {
        let fetchRequest: NSFetchRequest<CDSongLessonSession> = CDSongLessonSession.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "isFavorite == YES")
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \CDSongLessonSession.lastAccessed, ascending: false)]
        
        do {
            return try coreDataService.context.fetch(fetchRequest)
        } catch {
            print("Error fetching favorite song lesson sessions: \(error)")
            return []
        }
    }
    
    func clearFavoriteSongs() throws {
        let fetchRequest: NSFetchRequest<CDSongLessonSession> = CDSongLessonSession.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "isFavorite == YES")
        
        let favorites = try coreDataService.context.fetch(fetchRequest)
        guard !favorites.isEmpty else { return }
        
        favorites.forEach { $0.isFavorite = false }
        try coreDataService.saveContext()
        
        NotificationCenter.default.post(name: .songSessionDidChange, object: nil)
    }
    
    func deleteAllSessions() throws {
        let fetchRequest: NSFetchRequest<CDSongLessonSession> = CDSongLessonSession.fetchRequest()
        let sessions = try coreDataService.context.fetch(fetchRequest)
        
        guard !sessions.isEmpty else { return }
        
        sessions.forEach { coreDataService.context.delete($0) }
        try coreDataService.saveContext()
        
        NotificationCenter.default.post(name: .songSessionDidChange, object: nil)
    }
    
    func getSession(by songId: String) -> CDSongLessonSession? {
        let fetchRequest: NSFetchRequest<CDSongLessonSession> = CDSongLessonSession.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "songId == %@", songId)
        fetchRequest.fetchLimit = 1
        
        do {
            return try coreDataService.context.fetch(fetchRequest).first
        } catch {
            print("Error fetching song lesson session: \(error)")
            return nil
        }
    }
    
    func getSession(by id: UUID) -> CDSongLessonSession? {
        let fetchRequest: NSFetchRequest<CDSongLessonSession> = CDSongLessonSession.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        fetchRequest.fetchLimit = 1
        
        do {
            return try coreDataService.context.fetch(fetchRequest).first
        } catch {
            print("Error fetching song lesson session: \(error)")
            return nil
        }
    }
    
    // MARK: - Update Favorite Status
    
    func toggleFavorite(song: Song) throws {
        if let session = getSession(by: song.id) {
            // Session exists, just toggle favorite
            session.isFavorite.toggle()
            try coreDataService.saveContext()
            
            print("✅ [SongLessonSessionService] Toggled favorite for existing session: \(session.isFavorite)")
            
            // Notify that session data changed
            NotificationCenter.default.post(name: .songSessionDidChange, object: nil)
        } else {
            // No session exists, create a minimal one for favorite tracking
            let cdSession = CDSongLessonSession(context: coreDataService.context)
            cdSession.id = UUID()
            cdSession.date = Date()
            cdSession.lastAccessed = Date()
            cdSession.song = song  // This also sets songId automatically
            cdSession.isFavorite = true
            cdSession.isComplete = false
            cdSession.totalQuestions = 0
            
            try coreDataService.saveContext()
            
            print("✅ [SongLessonSessionService] Created new favorite session for: \(song.title)")
            
            // Notify that session data changed
            NotificationCenter.default.post(name: .songSessionDidChange, object: nil)
        }
    }
    
    // MARK: - Delete Session
    
    func deleteSession(_ session: CDSongLessonSession) throws {
        coreDataService.context.delete(session)
        try coreDataService.saveContext()
        
        // Notify that session data changed
        NotificationCenter.default.post(name: .songSessionDidChange, object: nil)
    }
}

