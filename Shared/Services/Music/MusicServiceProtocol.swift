//
//  MusicServiceProtocol.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin
//

import Foundation

protocol MusicServiceProtocol {
    /// The type of music service
    var serviceType: MusicServiceType { get }
    
    /// Authenticate with the music service
    func authenticate() async throws
    
    /// Check if user is authenticated
    func isAuthenticated() -> Bool
    
    /// Search for songs by query string
    /// - Parameters:
    ///   - query: Search query
    ///   - language: Optional language filter
    /// - Returns: Array of matching songs
    func searchSongs(query: String, language: String?) async throws -> [Song]
    
    /// Get user's saved songs/library
    /// - Parameter limit: Maximum number of songs to return
    /// - Returns: Array of user's songs
    func getUserLibrary(limit: Int) async throws -> [Song]
    
    /// Get user's playlists
    /// - Returns: Array of user playlists (basic info only, can extend later)
    func getUserPlaylists() async throws -> [PlaylistInfo]
    
    /// Get detailed song metadata
    /// - Parameter id: Song ID (service-specific)
    /// - Returns: Song with full metadata
    func getSongMetadata(id: String) async throws -> Song
    
    /// Detect language for a song
    /// - Parameter song: Song to detect language for
    /// - Returns: Language code (ISO 639-1)
    func detectLanguage(for song: Song) async throws -> String
    
    /// Sign out from the service
    func signOut() async throws
}

/// Basic playlist info structure
struct PlaylistInfo: Identifiable, Codable {
    let id: String
    let name: String
    let description: String?
    let artworkURL: URL?
    let trackCount: Int
    let serviceType: MusicServiceType
}

