//
//  StoryLabSessionService.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin
//

import Foundation
import CoreData
import Combine

final class StoryLabSessionService {
    
    static let shared = StoryLabSessionService()
    
    private let coreDataService = CoreDataService.shared
    
    private init() {}
    
    // MARK: - Save Session
    
    func saveOrUpdateSession(_ session: StorySession, config: StoryLabConfig, story: AIStoryResponse) async throws {
        // Check if session already exists
        if let existingSession = getSession(by: session.id) {
            // Update existing session
            existingSession.updateFromSession(session)
            existingSession.story = story
            existingSession.config = config
        } else {
            // Create new session
            let cdSession = CDStoryLabSession(context: coreDataService.context)
            cdSession.id = session.id
            cdSession.date = Date()
            cdSession.story = story
            cdSession.config = config
            cdSession.totalQuestions = Int32(session.totalQuestions)
            cdSession.updateFromSession(session)
        }
        
        try coreDataService.saveContext()
    }
    
    // Deprecated: Use saveOrUpdateSession instead
    func saveSession(_ session: StorySession, config: StoryLabConfig, story: AIStoryResponse) async throws {
        try await saveOrUpdateSession(session, config: config, story: story)
    }
    
    // MARK: - Load Sessions
    
    func getAllSessions() -> [CDStoryLabSession] {
        let fetchRequest: NSFetchRequest<CDStoryLabSession> = CDStoryLabSession.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \CDStoryLabSession.date, ascending: false)]
        
        do {
            return try coreDataService.context.fetch(fetchRequest)
        } catch {
            print("Error fetching story lab sessions: \(error)")
            return []
        }
    }
    
    func getIncompleteSessions() -> [CDStoryLabSession] {
        let fetchRequest: NSFetchRequest<CDStoryLabSession> = CDStoryLabSession.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "isComplete == NO")
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \CDStoryLabSession.date, ascending: false)]
        
        do {
            return try coreDataService.context.fetch(fetchRequest)
        } catch {
            print("Error fetching incomplete story lab sessions: \(error)")
            return []
        }
    }
    
    func getLatestIncompleteSession() -> CDStoryLabSession? {
        return getIncompleteSessions().first
    }
    
    func getSession(by id: UUID) -> CDStoryLabSession? {
        let fetchRequest: NSFetchRequest<CDStoryLabSession> = CDStoryLabSession.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        fetchRequest.fetchLimit = 1
        
        do {
            return try coreDataService.context.fetch(fetchRequest).first
        } catch {
            print("Error fetching story lab session: \(error)")
            return nil
        }
    }
    
    // MARK: - Delete Session
    
    func deleteSession(_ session: CDStoryLabSession) throws {
        coreDataService.context.delete(session)
        try coreDataService.saveContext()
    }
}

