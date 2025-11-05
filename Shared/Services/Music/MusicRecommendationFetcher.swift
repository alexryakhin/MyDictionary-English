//
//  MusicRecommendationFetcher.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin
//

import Foundation

/// Service for fetching random songs from artist/album recommendations
final class MusicRecommendationFetcher {
    
    static let shared = MusicRecommendationFetcher()
    
    private let appleMusicService = AppleMusicService.shared
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// Fetch a random song from an artist recommendation
    /// - Parameter artist: The artist recommendation (contains only name, no ID)
    /// - Returns: Random song from the artist, or nil if not found
    func fetchRandomSong(for artist: RecommendationArtist) async throws -> Song? {
        guard appleMusicService.isAuthorized else {
            throw MusicError.authenticationRequired
        }
        
        // Search for songs by artist name directly
        let songs = try await appleMusicService.getArtistSongs(artistName: artist.name, limit: 20)
        return songs.randomElement()
    }
    
    /// Fetch a random song from an album recommendation
    /// - Parameter album: The album recommendation (contains only name and artist, no ID)
    /// - Returns: Random song from the album, or nil if not found
    func fetchRandomSong(for album: RecommendationAlbum) async throws -> Song? {
        guard appleMusicService.isAuthorized else {
            throw MusicError.authenticationRequired
        }
        
        // Search for songs from album by name and artist directly
        let songs = try await appleMusicService.getAlbumSongs(albumName: album.name, artistName: album.artist)
        return songs.randomElement()
    }
}

