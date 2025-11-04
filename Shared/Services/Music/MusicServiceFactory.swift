//
//  MusicServiceFactory.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin
//

import Foundation

final class MusicServiceFactory {
    static let shared = MusicServiceFactory()
    
    private var appleMusicService: MusicServiceProtocol?
    private var spotifyService: MusicServiceProtocol?
    
    private init() {}
    
    /// Creates or returns existing service instance for the given type
    /// - Parameter type: Music service type
    /// - Returns: Music service protocol instance
    func createService(type: MusicServiceType) -> MusicServiceProtocol {
        switch type {
        case .appleMusic:
            if let existing = appleMusicService {
                return existing
            }
            let service = AppleMusicService.shared
            appleMusicService = service
            return service
            
        case .spotify:
            if let existing = spotifyService {
                return existing
            }
            let service = SpotifyService.shared
            spotifyService = service
            return service
        }
    }
    
    /// Gets all available services
    /// - Returns: Array of all music service instances
    func getAllServices() -> [MusicServiceProtocol] {
        return [
            createService(type: .appleMusic),
            createService(type: .spotify)
        ]
    }
    
    /// Gets services that are authenticated
    /// - Returns: Array of authenticated music services
    func getAuthenticatedServices() -> [MusicServiceProtocol] {
        return getAllServices().filter { $0.isAuthenticated() }
    }
}

