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

    func searchSongs(query: String, language: String?) async throws -> [Song] {
        guard isAuthorized else {
            throw MusicError.authenticationRequired
        }
        
        var searchRequest = MusicCatalogSearchRequest(term: query, types: [MusicKit.Song.self])
        
        if let language = language {
            // Language filtering can be added if MusicKit supports it
            // For now, we'll search without language filter
        }
        
        do {
            let response = try await searchRequest.response()
            return response.songs.compactMap { musicKitSong in
                convertToUnifiedSong(from: musicKitSong)
            }
        } catch {
            throw MusicError.networkError(error.localizedDescription)
        }
    }
    
    func getUserLibrary(limit: Int) async throws -> [Song] {
        guard isAuthorized else {
            throw MusicError.authenticationRequired
        }
        
        let query = MPMediaQuery.songs()
        query.addFilterPredicate(MPMediaPropertyPredicate(
            value: NSNumber(value: MPMediaType.music.rawValue),
            forProperty: MPMediaItemPropertyMediaType
        ))
        
        guard let items = query.items, items.count > 0 else {
            return []
        }
        
        return Array(items.prefix(limit)).compactMap { item in
            convertToUnifiedSong(from: item)
        }
    }
    
    func getUserPlaylists() async throws -> [PlaylistInfo] {
        guard isAuthorized else {
            throw MusicError.authenticationRequired
        }
        
        let query = MPMediaQuery.playlists()
        
        guard let collections = query.collections else {
            return []
        }
        
        return collections.compactMap { collection in
            guard let representativeItem = collection.representativeItem,
                  let playlistName = representativeItem.value(forProperty: MPMediaPlaylistPropertyName) as? String else {
                return nil
            }
            
            let playlistId = UUID().uuidString // MPMediaPlaylist doesn't expose stable ID
            let trackCount = collection.count
            let artwork = representativeItem.artwork
            
            return PlaylistInfo(
                id: playlistId,
                name: playlistName,
                description: nil,
                artworkURL: nil, // MPMediaItem artwork is not URL-based
                trackCount: trackCount
            )
        }
    }
    
    func getSongMetadata(id: String) async throws -> Song {
        guard isAuthorized else {
            throw MusicError.authenticationRequired
        }
        
        // Try to find song by ID
        let searchRequest = MusicCatalogSearchRequest(term: id, types: [MusicKit.Song.self])
        
        do {
            let response = try await searchRequest.response()
            if let musicKitSong = response.songs.first,
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
    
    func detectLanguage(for song: Song) async throws -> String {
        // For now, return a default language
        // This could be enhanced with language detection API or ML model
        // Using the song's title/artist metadata to infer language
        return "en" // Default to English, can be enhanced later
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
            previewURL: nil,
            serviceId: id
        )
    }
    
    private func convertToUnifiedSong(from mediaItem: MPMediaItem) -> Song? {
        guard let title = mediaItem.title,
              let artist = mediaItem.artist else {
            return nil
        }
        
        let id = String(mediaItem.persistentID)
        let duration = mediaItem.playbackDuration
        let album = mediaItem.albumTitle
        let artwork = mediaItem.artwork
        
        var artworkURL: URL? = nil
        if let artwork = artwork {
            // MPMediaItem artwork is not URL-based, we'll need to handle it differently
            // For now, set to nil - can be enhanced to extract image data
        }
        
        return Song(
            id: id,
            title: title,
            artist: artist,
            album: album,
            albumArtURL: artworkURL,
            duration: duration,
            previewURL: nil,
            serviceId: id
        )
    }
}

