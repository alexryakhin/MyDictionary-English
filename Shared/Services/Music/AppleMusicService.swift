//
//  AppleMusicService.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin
//

import Foundation
import MusicKit
import MediaPlayer

/// Basic playlist info structure
struct PlaylistInfo: Identifiable, Codable {
    let id: String
    let name: String
    let description: String?
    let artworkURL: URL?
    let trackCount: Int
}

final class AppleMusicService {

    static let shared = AppleMusicService()

    private(set) var isAuthorized: Bool {
        get { UDService.appleMusicAuthorized }
        set { UDService.appleMusicAuthorized = newValue }
    }
    
    private init() {}
    
    func authenticate() async throws {
        let status = await MusicAuthorization.request()
        
        switch status {
        case .authorized:
            // Test if MusicKit is properly registered by attempting a simple search
            do {
                let testRequest = MusicCatalogSearchRequest(term: "test", types: [MusicKit.Song.self])
                _ = try await testRequest.response()
                isAuthorized = true
                return
            } catch {
                // Check if it's a registration/subscription error
                let errorDescription = error.localizedDescription.lowercased()
                if errorDescription.contains("404") || errorDescription.contains("client not found") || errorDescription.contains("not registered") {
                    isAuthorized = false
                    throw MusicError.appleMusicNotRegistered
                } else if errorDescription.contains("subscription") || errorDescription.contains("not found") {
                    isAuthorized = false
                    throw MusicError.appleMusicSubscriptionRequired
                } else {
                    isAuthorized = false
                    throw MusicError.authenticationFailed(error.localizedDescription)
                }
            }
        case .denied, .notDetermined, .restricted:
            isAuthorized = false
            throw MusicError.authenticationFailed("MusicKit authorization was denied")
        @unknown default:
            isAuthorized = false
            throw MusicError.authenticationFailed("Unknown authorization status")
        }
    }

    func searchSongs(query: String) async throws -> [Song] {
        guard isAuthorized else {
            throw MusicError.appleMusicNotRegistered
        }
        
        var searchRequest = MusicCatalogSearchRequest(term: query, types: [MusicKit.Song.self])

        do {
            let response = try await searchRequest.response()
            logInfo("[AppleMusicService] Found songs: \(response.songs.map(\.title))")
            return response.songs.filter({ $0.contentRating != .explicit }).compactMap { musicKitSong in
                return convertToUnifiedSong(from: musicKitSong)
            }
        } catch {
            throw MusicError.networkError(error.localizedDescription)
        }
    }
    
//    func getUserLibrary(limit: Int) async throws -> [Song] {
//        guard isAuthorized else {
//            throw MusicError.appleMusicNotRegistered
//        }
//        
//        let query = MPMediaQuery.songs()
//        query.addFilterPredicate(MPMediaPropertyPredicate(
//            value: NSNumber(value: MPMediaType.music.rawValue),
//            forProperty: MPMediaItemPropertyMediaType
//        ))
//        
//        guard let items = query.items, items.count > 0 else {
//            return []
//        }
//        
//        return Array(items.prefix(limit)).compactMap { item in
//            convertToUnifiedSong(from: item)
//        }
//    }
    
//    func getUserPlaylists() async throws -> [PlaylistInfo] {
//        guard isAuthorized else {
//            throw MusicError.appleMusicNotRegistered
//        }
//        
//        let query = MPMediaQuery.playlists()
//        
//        guard let collections = query.collections else {
//            return []
//        }
//        
//        return collections.compactMap { collection in
//            guard let representativeItem = collection.representativeItem,
//                  let playlistName = representativeItem.value(forProperty: MPMediaPlaylistPropertyName) as? String else {
//                return nil
//            }
//            
//            let playlistId = UUID().uuidString // MPMediaPlaylist doesn't expose stable ID
//            let trackCount = collection.count
//            let artwork = representativeItem.artwork
//            
//            return PlaylistInfo(
//                id: playlistId,
//                name: playlistName,
//                description: nil,
//                artworkURL: nil, // MPMediaItem artwork is not URL-based
//                trackCount: trackCount
//            )
//        }
//    }
    
    func getSongMetadata(id: String) async throws -> Song {
        guard isAuthorized else {
            throw MusicError.appleMusicNotRegistered
        }
        
        // Try to find song by ID
        let searchRequest = MusicCatalogSearchRequest(term: id, types: [MusicKit.Song.self])
        
        do {
            let response = try await searchRequest.response()
            logInfo("[AppleMusicService] Found songs: \(response.songs.map(\.title))")
            if let musicKitSong = response.songs.filter({ $0.contentRating != .explicit }).first,
               let unifiedSong = convertToUnifiedSong(from: musicKitSong) {
                return unifiedSong
            }
            throw MusicError.songNotFound
        } catch let error as MusicError {
            throw error
        } catch {
            throw MusicError.networkError(error.localizedDescription)
        }
    }

    /// Search for artists in Apple Music
    /// - Parameter query: Search query (artist name)
    /// - Returns: Array of artist information
    func searchArtists(query: String) async throws -> [ArtistInfo] {
        guard isAuthorized else {
            throw MusicError.appleMusicNotRegistered
        }
        
        let searchRequest = MusicCatalogSearchRequest(term: query, types: [MusicKit.Artist.self])
        
        do {
            let response = try await searchRequest.response()
            return response.artists.compactMap { musicKitArtist in
                convertToArtistInfo(from: musicKitArtist)
            }
        } catch {
            throw MusicError.networkError(error.localizedDescription)
        }
    }
    
    /// Get songs from an artist
    /// - Parameters:
    ///   - artistId: Apple Music artist ID (can be used if available)
    ///   - artistName: Artist name for searching (preferred)
    ///   - limit: Maximum number of songs to return
    /// - Returns: Array of songs from the artist
    func getArtistSongs(artistId: String? = nil, artistName: String? = nil, limit: Int = 10) async throws -> [Song] {
        guard isAuthorized else {
            throw MusicError.appleMusicNotRegistered
        }
        
        // Prefer searching by artist name if provided
        let searchTerm: String
        if let artistName = artistName, !artistName.isEmpty {
            searchTerm = artistName
        } else if let artistId = artistId {
            searchTerm = artistId
        } else {
            throw MusicError.songNotFound
        }
        
        // Search for songs by this artist
        let songSearchRequest = MusicCatalogSearchRequest(term: searchTerm, types: [MusicKit.Song.self])
        let songResponse = try await songSearchRequest.response()
        logInfo("[AppleMusicService] Found songs: \(songResponse.songs.map(\.title))")
        // Filter songs by artist name (if provided) and return selection
        let artistSongs: [MusicKit.Song]
        if let artistName = artistName {
            artistSongs = songResponse.songs
                .filter { $0.artistName.lowercased().contains(artistName.lowercased()) }
                .filter { $0.contentRating != .explicit }
                .shuffled()
                .prefix(limit)
                .map { $0 }
        } else {
            artistSongs = Array(songResponse.songs.filter({ $0.contentRating != .explicit }).prefix(limit))
        }
        
        return artistSongs.compactMap { musicKitSong in
            convertToUnifiedSong(from: musicKitSong)
        }
    }
    
    /// Search for albums in Apple Music
    /// - Parameter query: Search query (album name or artist)
    /// - Returns: Array of album information
    func searchAlbums(query: String) async throws -> [AlbumInfo] {
        guard isAuthorized else {
            throw MusicError.appleMusicNotRegistered
        }
        
        let searchRequest = MusicCatalogSearchRequest(term: query, types: [MusicKit.Album.self])
        
        do {
            let response = try await searchRequest.response()
            return response.albums.compactMap { musicKitAlbum in
                convertToAlbumInfo(from: musicKitAlbum)
            }
        } catch {
            throw MusicError.networkError(error.localizedDescription)
        }
    }
    
    /// Get songs from an album
    /// - Parameters:
    ///   - albumId: Apple Music album ID (can be used if available)
    ///   - albumName: Album name for searching (preferred)
    ///   - artistName: Artist name for better matching
    /// - Returns: Array of songs from the album
    func getAlbumSongs(albumId: String? = nil, albumName: String? = nil, artistName: String? = nil) async throws -> [Song] {
        guard isAuthorized else {
            throw MusicError.appleMusicNotRegistered
        }
        
        // Prefer searching by album name and artist if provided
        let searchTerm: String
        if let albumName = albumName, let artistName = artistName {
            searchTerm = "\(albumName) \(artistName)"
        } else if let albumName = albumName {
            searchTerm = albumName
        } else if let albumId = albumId {
            searchTerm = albumId
        } else {
            throw MusicError.songNotFound
        }
        
        // Search for album
        let searchRequest = MusicCatalogSearchRequest(term: searchTerm, types: [MusicKit.Album.self])
        let response = try await searchRequest.response()
        
        // Try to find exact match if album name and artist provided
        let album: MusicKit.Album?
        if let albumName = albumName, let artistName = artistName {
            album = response.albums.first(where: {
                $0.title.lowercased().contains(albumName.lowercased()) &&
                $0.artistName.lowercased().contains(artistName.lowercased())
            }) ?? response.albums.first
        } else {
            album = response.albums.first
        }
        
        guard let foundAlbum = album else {
            throw MusicError.songNotFound
        }
        
        // Get tracks from the album
        let tracks = foundAlbum.tracks ?? []
        return tracks.compactMap { track in
            if let song = track as? MusicKit.Song {
                return convertToUnifiedSong(from: song)
            }
            return nil
        }
    }
    
    func signOut() {
        // Apple Music doesn't require explicit sign out
        isAuthorized = false
    }
    
    // MARK: - Private Helpers
    
    private func convertToUnifiedSong(from musicKitSong: MusicKit.Song) -> Song? {
        // Convert MusicItemID to String
        let id = String(describing: musicKitSong.id)
        
        let duration = musicKitSong.duration ?? 0
        
        // Get artwork URL
        var artworkURL: URL? = nil
        if let artwork = musicKitSong.artwork {
            artworkURL = artwork.url(width: 500, height: 500)
        }
        
        return Song(
            id: id,
            title: musicKitSong.title,
            artist: musicKitSong.artistName,
            album: musicKitSong.albumTitle,
            albumArtURL: artworkURL,
            duration: duration,
            serviceId: id
        )
    }
    
//    private func convertToUnifiedSong(from mediaItem: MPMediaItem) -> Song? {
//        guard let title = mediaItem.title,
//              let artist = mediaItem.artist else {
//            return nil
//        }
//        
//        let id = String(mediaItem.persistentID)
//        let duration = mediaItem.playbackDuration
//        let album = mediaItem.albumTitle
//        let artwork = mediaItem.artwork
//        
//        var artworkURL: URL? = nil
//        if let artwork = artwork {
//            // MPMediaItem artwork is not URL-based, we'll need to handle it differently
//            // For now, set to nil - can be enhanced to extract image data
//        }
//        
//        return Song(
//            id: id,
//            title: title,
//            artist: artist,
//            album: album,
//            albumArtURL: artworkURL,
//            duration: duration,
//            serviceId: id
//        )
//    }
    
    private func convertToArtistInfo(from musicKitArtist: MusicKit.Artist) -> ArtistInfo? {
        let id = String(describing: musicKitArtist.id)
        var artworkURL: URL? = nil
        if let artwork = musicKitArtist.artwork {
            artworkURL = artwork.url(width: 500, height: 500)
        }
        
        return ArtistInfo(
            id: id,
            name: musicKitArtist.name,
            artworkURL: artworkURL
        )
    }
    
    private func convertToAlbumInfo(from musicKitAlbum: MusicKit.Album) -> AlbumInfo? {
        let id = String(describing: musicKitAlbum.id)
        var artworkURL: URL? = nil
        if let artwork = musicKitAlbum.artwork {
            artworkURL = artwork.url(width: 500, height: 500)
        }
        
        return AlbumInfo(
            id: id,
            name: musicKitAlbum.title,
            artist: musicKitAlbum.artistName,
            artworkURL: artworkURL
        )
    }
}

// MARK: - Artist and Album Info Models

struct ArtistInfo: Identifiable, Codable {
    let id: String
    let name: String
    let artworkURL: URL?
}

struct AlbumInfo: Identifiable, Codable {
    let id: String
    let name: String
    let artist: String
    let artworkURL: URL?
}

