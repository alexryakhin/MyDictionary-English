//
//  SpotifyService.swift
//  My Dictionary
//
//  Created by AI Assistant
//

import Foundation

final class SpotifyService: MusicServiceProtocol {
    static let shared = SpotifyService()
    
    var serviceType: MusicServiceType {
        return .spotify
    }
    
    private let baseURL = "https://api.spotify.com/v1"
    private let authURL = "https://accounts.spotify.com"
    private let session = URLSession.shared
    private let remoteConfigService = RemoteConfigService.shared
    
    private let authManager = MusicAuthenticationManager.shared
    
    private var clientID: String? {
        return remoteConfigService.getSpotifyClientID()
    }
    
    private var clientSecret: String? {
        return remoteConfigService.getSpotifyClientSecret()
    }
    
    private var redirectURI: String {
        // Spotify redirect URI - should match Spotify app settings
        return "mydictionary://spotify-callback"
    }
    
    private var accessToken: String? {
        let tokens = authManager.loadSpotifyTokens()
        return tokens.accessToken
    }
    
    private var refreshToken: String? {
        let tokens = authManager.loadSpotifyTokens()
        return tokens.refreshToken
    }
    
    private var tokenExpirationDate: Date? {
        let tokens = authManager.loadSpotifyTokens()
        return tokens.expirationDate
    }
    
    private init() {}
    
    func authenticate() async throws {
        guard let clientID = clientID else {
            throw MusicError.authenticationFailed("Spotify client ID not configured")
        }
        
        // Start OAuth2 flow
        // This will require UI interaction (browser/webview)
        // For now, we'll throw an error - the UI layer will handle the OAuth flow
        throw MusicError.authenticationRequired
    }
    
    func isAuthenticated() -> Bool {
        guard let token = accessToken,
              let expiration = tokenExpirationDate,
              expiration > Date() else {
            return false
        }
        return true
    }
    
    func searchSongs(query: String, language: String?) async throws -> [Song] {
        guard isAuthenticated() else {
            throw MusicError.authenticationRequired
        }
        
        guard let accessToken = accessToken else {
            throw MusicError.authenticationRequired
        }
        
        // Refresh token if needed
        try await refreshTokenIfNeeded()
        
        var components = URLComponents(string: "\(baseURL)/search")
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "type", value: "track"),
            URLQueryItem(name: "limit", value: "50")
        ]
        
        if let language = language {
            // Add market parameter for language-based results
            queryItems.append(URLQueryItem(name: "market", value: language))
        }
        
        components?.queryItems = queryItems
        
        guard let url = components?.url else {
            throw MusicError.networkError("Invalid URL")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                if let httpResponse = response as? HTTPURLResponse,
                   httpResponse.statusCode == 401 {
                    // Token expired, try to refresh
                    try await refreshAccessToken()
                    // Retry request with new token
                    return try await searchSongs(query: query, language: language)
                }
                throw MusicError.invalidResponse
            }
            
            let searchResponse = try JSONDecoder().decode(SpotifySearchResponse.self, from: data)
            return searchResponse.tracks.items.compactMap { track in
                convertToUnifiedSong(from: track)
            }
            
        } catch let error as MusicError {
            throw error
        } catch {
            throw MusicError.networkError(error.localizedDescription)
        }
    }
    
    func getUserLibrary(limit: Int) async throws -> [Song] {
        guard isAuthenticated() else {
            throw MusicError.authenticationRequired
        }
        
        guard let accessToken = accessToken else {
            throw MusicError.authenticationRequired
        }
        
        try await refreshTokenIfNeeded()
        
        var components = URLComponents(string: "\(baseURL)/me/tracks")
        components?.queryItems = [
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "offset", value: "0")
        ]
        
        guard let url = components?.url else {
            throw MusicError.networkError("Invalid URL")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                if let httpResponse = response as? HTTPURLResponse,
                   httpResponse.statusCode == 401 {
                    try await refreshAccessToken()
                    return try await getUserLibrary(limit: limit)
                }
                throw MusicError.invalidResponse
            }
            
            let libraryResponse = try JSONDecoder().decode(SpotifyLibraryResponse.self, from: data)
            return libraryResponse.items.compactMap { item in
                convertToUnifiedSong(from: item.track)
            }
            
        } catch let error as MusicError {
            throw error
        } catch {
            throw MusicError.networkError(error.localizedDescription)
        }
    }
    
    func getUserPlaylists() async throws -> [PlaylistInfo] {
        guard isAuthenticated() else {
            throw MusicError.authenticationRequired
        }
        
        guard let accessToken = accessToken else {
            throw MusicError.authenticationRequired
        }
        
        try await refreshTokenIfNeeded()
        
        var components = URLComponents(string: "\(baseURL)/me/playlists")
        components?.queryItems = [
            URLQueryItem(name: "limit", value: "50"),
            URLQueryItem(name: "offset", value: "0")
        ]
        
        guard let url = components?.url else {
            throw MusicError.networkError("Invalid URL")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                if let httpResponse = response as? HTTPURLResponse,
                   httpResponse.statusCode == 401 {
                    try await refreshAccessToken()
                    return try await getUserPlaylists()
                }
                throw MusicError.invalidResponse
            }
            
            let playlistsResponse = try JSONDecoder().decode(SpotifyPlaylistsResponse.self, from: data)
            return playlistsResponse.items.map { playlist in
                PlaylistInfo(
                    id: playlist.id,
                    name: playlist.name,
                    description: playlist.description,
                    artworkURL: playlist.images?.first?.url,
                    trackCount: playlist.tracks.total,
                    serviceType: .spotify
                )
            }
            
        } catch let error as MusicError {
            throw error
        } catch {
            throw MusicError.networkError(error.localizedDescription)
        }
    }
    
    func getSongMetadata(id: String) async throws -> Song {
        guard isAuthenticated() else {
            throw MusicError.authenticationRequired
        }
        
        guard let accessToken = accessToken else {
            throw MusicError.authenticationRequired
        }
        
        try await refreshTokenIfNeeded()
        
        let urlString = "\(baseURL)/tracks/\(id)"
        guard let url = URL(string: urlString) else {
            throw MusicError.networkError("Invalid URL")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                throw MusicError.songNotFound
            }
            
            let track = try JSONDecoder().decode(SpotifyTrack.self, from: data)
            
            guard let song = convertToUnifiedSong(from: track) else {
                throw MusicError.songNotFound
            }
            
            return song
            
        } catch let error as MusicError {
            throw error
        } catch {
            throw MusicError.networkError(error.localizedDescription)
        }
    }
    
    func detectLanguage(for song: Song) async throws -> String {
        // For now, return a default language
        // This could be enhanced with language detection API or ML model
        return "en" // Default to English, can be enhanced later
    }
    
    func signOut() async throws {
        authManager.clearSpotifyTokens()
    }
    
    // MARK: - Token Management
    
    /// Sets tokens after OAuth flow completion
    func setTokens(accessToken: String, refreshToken: String, expiresIn: TimeInterval) {
        authManager.saveSpotifyTokens(
            accessToken: accessToken,
            refreshToken: refreshToken,
            expiresIn: expiresIn
        )
    }
    
    private func refreshTokenIfNeeded() async throws {
        guard let expiration = tokenExpirationDate,
              expiration <= Date() else {
            return
        }
        
        try await refreshAccessToken()
    }
    
    private func refreshAccessToken() async throws {
        guard let currentRefreshToken = refreshToken,
              let clientID = clientID,
              let clientSecret = clientSecret else {
            throw MusicError.tokenRefreshFailed
        }
        
        let urlString = "\(authURL)/api/token"
        guard let url = URL(string: urlString) else {
            throw MusicError.networkError("Invalid URL")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let authString = "\(clientID):\(clientSecret)"
        guard let authData = authString.data(using: .utf8) else {
            throw MusicError.authenticationFailed("Failed to encode credentials")
        }
        let authValue = "Basic \(authData.base64EncodedString())"
        request.setValue(authValue, forHTTPHeaderField: "Authorization")
        
        let bodyString = "grant_type=refresh_token&refresh_token=\(currentRefreshToken)"
        request.httpBody = bodyString.data(using: .utf8)
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                throw MusicError.tokenRefreshFailed
            }
            
            let tokenResponse = try JSONDecoder().decode(SpotifyTokenResponse.self, from: data)
            
            // Update tokens
            let refreshTokenToSave = tokenResponse.refreshToken ?? self.refreshToken ?? ""
            authManager.saveSpotifyTokens(
                accessToken: tokenResponse.accessToken,
                refreshToken: refreshTokenToSave,
                expiresIn: tokenResponse.expiresIn
            )
            
        } catch {
            throw MusicError.tokenRefreshFailed
        }
    }
    
    // MARK: - Conversion Helpers
    
    private func convertToUnifiedSong(from track: SpotifyTrack) -> Song? {
        guard let id = track.id,
              let name = track.name,
              let artists = track.artists,
              artists.count > 0,
              let artistName = artists.first?.name else {
            return nil
        }
        
        let duration = TimeInterval(track.durationMs ?? 0) / 1000.0 // Convert from milliseconds
        let albumName = track.album?.name
        let artworkURL = track.album?.images?.first?.url
        let previewURL = track.previewUrl
        
        return Song(
            id: id,
            title: name,
            artist: artistName,
            album: albumName,
            albumArtURL: artworkURL,
            duration: duration,
            previewURL: previewURL,
            serviceType: .spotify,
            serviceId: id
        )
    }
}

// MARK: - Spotify API Models

struct SpotifySearchResponse: Codable {
    let tracks: SpotifyTracksContainer
}

struct SpotifyTracksContainer: Codable {
    let items: [SpotifyTrack]
    let total: Int
}

struct SpotifyTrack: Codable {
    let id: String?
    let name: String?
    let artists: [SpotifyArtist]?
    let album: SpotifyAlbum?
    let durationMs: Int?
    let previewUrl: URL?
    
    enum CodingKeys: String, CodingKey {
        case id, name, artists, album
        case durationMs = "duration_ms"
        case previewUrl = "preview_url"
    }
}

struct SpotifyArtist: Codable {
    let id: String?
    let name: String?
}

struct SpotifyAlbum: Codable {
    let id: String?
    let name: String?
    let images: [SpotifyImage]?
}

struct SpotifyImage: Codable {
    let url: URL?
    let height: Int?
    let width: Int?
}

struct SpotifyLibraryResponse: Codable {
    let items: [SpotifySavedTrack]
}

struct SpotifySavedTrack: Codable {
    let track: SpotifyTrack
    let addedAt: String?
    
    enum CodingKeys: String, CodingKey {
        case track
        case addedAt = "added_at"
    }
}

struct SpotifyPlaylistsResponse: Codable {
    let items: [SpotifyPlaylist]
}

struct SpotifyPlaylist: Codable {
    let id: String
    let name: String
    let description: String?
    let images: [SpotifyImage]?
    let tracks: SpotifyPlaylistTracks
}

struct SpotifyPlaylistTracks: Codable {
    let total: Int
}

struct SpotifyTokenResponse: Codable {
    let accessToken: String
    let refreshToken: String?
    let expiresIn: TimeInterval
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
    }
}

