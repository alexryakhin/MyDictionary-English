//
//  LRCLibService.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin
//

import Foundation

final class LRCLibService {
    static let shared = LRCLibService()
    
    private let baseURL = "https://lrclib.net"
    private let session = URLSession.shared
    
    private init() {}
    
    /// Fetch lyrics for a song using track signature
    /// - Parameters:
    ///   - trackName: Song title
    ///   - artistName: Artist name
    ///   - albumName: Album name (optional)
    ///   - duration: Song duration in seconds (critical for matching, must be ±2 seconds)
    /// - Returns: SongLyrics model with lyrics data
    func getLyrics(
        trackName: String,
        artistName: String,
        albumName: String? = nil,
        duration: TimeInterval
    ) async throws -> SongLyrics {
        let durationSeconds = Int(duration.rounded())
        
        do {
            return try await fetchLyrics(
                trackName: trackName,
                artistName: artistName,
                albumName: albumName,
                durationSeconds: durationSeconds
            )
        } catch {
            logError("[LRCLibService] Failed to fetch lyrics, searching for a matching track, error: \(error.localizedDescription)")
            do {
                return try await searchForMatchingTrack(
                    trackName: trackName,
                    durationSeconds: durationSeconds
                )
            } catch {
                logError("[LRCLibService] Failed to search lyrics, error: \(error.localizedDescription)")
                throw error
            }
        }
    }
    
    /// Search for lyrics by keywords
    /// - Parameter query: Search query
    /// - Returns: Array of search results
    func searchLyrics(query: String) async throws -> [LRCLibSearchResult] {
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "\(baseURL)/api/search?q=\(encodedQuery)"
        
        guard let url = URL(string: urlString) else {
            throw MusicError.networkError("Invalid URL")
        }
        
        do {
            let (data, response) = try await session.data(from: url)
            
            // Validate response
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                throw MusicError.invalidResponse
            }
            
            let searchResponse = try JSONDecoder().decode(LRCLibSearchResponse.self, from: data)
            return searchResponse
            
        } catch let error as MusicError {
            throw error
        } catch {
            throw MusicError.networkError(error.localizedDescription)
        }
    }
    
    /// Try to get cached lyrics (faster response when available)
    /// - Parameters:
    ///   - trackName: Song title
    ///   - artistName: Artist name
    ///   - duration: Song duration in seconds
    /// - Returns: SongLyrics if found in cache
    func getCachedLyrics(
        trackName: String,
        artistName: String,
        duration: TimeInterval
    ) async throws -> SongLyrics? {
        let durationSeconds = Int(duration.rounded())
        
        var components = URLComponents(string: "\(baseURL)/api/get-cached")
        components?.queryItems = [
            URLQueryItem(name: "track_name", value: trackName),
            URLQueryItem(name: "artist_name", value: artistName),
            URLQueryItem(name: "duration", value: String(durationSeconds))
        ]
        
        guard let url = components?.url else {
            throw MusicError.networkError("Invalid URL")
        }
        
        do {
            let (data, response) = try await session.data(from: url)
            
            // 404 means no cached version, return nil
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 404 {
                return nil
            }
            
            // Validate response
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                return nil
            }
            
            let lrcResponse = try JSONDecoder().decode(LRCLibResponse.self, from: data)
            return lrcResponse.toSongLyrics()
            
        } catch {
            // Return nil on any error for cached endpoint
            return nil
        }
    }
}

// MARK: - Private Helpers

private extension LRCLibService {
    func fetchLyrics(
        trackName: String,
        artistName: String,
        albumName: String?,
        durationSeconds: Int
    ) async throws -> SongLyrics {
        var components = URLComponents(string: "\(baseURL)/api/get")
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "track_name", value: trackName),
            URLQueryItem(name: "artist_name", value: artistName),
            URLQueryItem(name: "duration", value: String(durationSeconds))
        ]
        
        if let albumName {
            queryItems.append(URLQueryItem(name: "album_name", value: albumName))
        }
        
        components?.queryItems = queryItems
        
        guard let url = components?.url else {
            throw MusicError.networkError("Invalid URL")
        }
        
        do {
            let (data, response) = try await session.data(from: url)
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 404 {
                throw MusicError.lyricsNotFound
            }
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                throw MusicError.invalidResponse
            }
            
            let lrcResponse = try JSONDecoder().decode(LRCLibResponse.self, from: data)
            return lrcResponse.toSongLyrics()
        } catch let error as MusicError {
            throw error
        } catch {
            throw MusicError.networkError(error.localizedDescription)
        }
    }
    
    func searchForMatchingTrack(
        trackName: String,
        durationSeconds: Int
    ) async throws -> SongLyrics {
        var components = URLComponents(string: "\(baseURL)/api/search")
        components?.queryItems = [
            URLQueryItem(name: "track_name", value: trackName)
        ]

        guard let url = components?.url else {
            throw MusicError.networkError("Invalid URL")
        }
        
        do {
            let (data, response) = try await session.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                throw MusicError.invalidResponse
            }
            
            let searchResponse = try JSONDecoder().decode(LRCLibSearchResponse.self, from: data)
            let tolerance = 3
            let filtered = searchResponse
                .sorted {
                    abs($0.roundedDurationSeconds - durationSeconds) < abs($1.roundedDurationSeconds - durationSeconds)
                }
                .first { abs($0.roundedDurationSeconds - durationSeconds) <= tolerance }
            
            guard let filtered else {
                throw MusicError.lyricsNotFound
            }
            return filtered.toSongLyrics()
        } catch let error as MusicError {
            throw error
        } catch {
            throw MusicError.networkError(error.localizedDescription)
        }
    }
}
