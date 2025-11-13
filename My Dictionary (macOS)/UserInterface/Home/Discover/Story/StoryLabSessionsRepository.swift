//
//  StoryLabSessionsRepository.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin
//

import Foundation
import Combine
import CoreData

final class StoryLabSessionsRepository: BaseViewModel {
    
    @Published private(set) var sessions: [CDStoryLabSession] = []
    
    private let sessionService = StoryLabSessionService.shared
    private var cancellables = Set<AnyCancellable>()
    
    override init() {
        super.init()
        setupReactiveUpdates()
        loadSessions()
    }
    
    // MARK: - Setup
    
    private func setupReactiveUpdates() {
        // Listen to Core Data changes to automatically refresh sessions
        CoreDataService.shared.dataUpdatedPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.loadSessions()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Load Sessions
    
    /// Loads sessions from Core Data
    /// Note: Must be called from main thread when updating @Published property
    func loadSessions() {
        // Ensure @Published update happens on main thread
        assert(Thread.isMainThread, "loadSessions() must update @Published on main thread")
        sessions = sessionService.getAllSessions()
    }
    
    // MARK: - Delete Session
    
    func deleteSession(_ session: CDStoryLabSession) throws {
        try sessionService.deleteSession(session)
        // Sessions will be reloaded automatically via Core Data publisher
    }
    
    func deleteSessions(at indices: IndexSet) {
        for index in indices {
            let session = sessions[index]
            do {
                try deleteSession(session)
            } catch {
                print("Error deleting session: \(error)")
            }
        }
    }
}

