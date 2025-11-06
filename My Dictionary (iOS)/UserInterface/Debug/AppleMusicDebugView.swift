//
//  AppleMusicDebugView.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin
//

// DO NOT TRANSLATE DEBUG
#if DEBUG
import SwiftUI
import Foundation

struct AppleMusicDebugView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var appleMusicService = AppleMusicService.shared
    @State private var lrcLibService = LRCLibService.shared
    
    @State private var searchQuery = ""
    @State private var searchResults: [Song] = []
    @State private var isSearching = false
    @State private var searchError: String?
    
    @State private var selectedSong: Song?
    @State private var songDetails: String?
    @State private var lyricsDetails: LyricsDebugInfo?
    @State private var isFetchingLyrics = false
    @State private var lyricsError: String?
    
    var body: some View {
        NavigationView {
            List {
                searchSection
                
                if !searchResults.isEmpty {
                    resultsSection
                }
                
                if let song = selectedSong {
                    songDetailsSection(song: song)
                }
                
                if let lyricsInfo = lyricsDetails {
                    lyricsDetailsSection(lyricsInfo: lyricsInfo)
                }
            }
            .navigationTitle("Apple Music Debug")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - Search Section
    
    private var searchSection: some View {
        Section("Search Apple Music") {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    TextField("Enter song title or artist", text: $searchQuery)
                        .textFieldStyle(.roundedBorder)
                        .autocorrectionDisabled()
                        #if os(iOS)
                        .textInputAutocapitalization(.never)
                        #endif
                    
                    Button("Search") {
                        performSearch()
                    }
                    .disabled(searchQuery.isEmpty || isSearching)
                }
                
                if isSearching {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Searching...")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                if let error = searchError {
                    Text("Error: \(error)")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
                
                HStack {
                    Text("Authorization Status:")
                        .fontWeight(.medium)
                    Spacer()
                    Text(appleMusicService.isAuthorized ? "Authorized" : "Not Authorized")
                        .foregroundStyle(appleMusicService.isAuthorized ? .green : .red)
                }
                
                Button("Request Authorization") {
                    Task {
                        do {
                            try await appleMusicService.authenticate()
                            await MainActor.run {
                                searchError = nil
                            }
                        } catch {
                            await MainActor.run {
                                searchError = error.localizedDescription
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Results Section
    
    private var resultsSection: some View {
        Section("Search Results (\(searchResults.count))") {
            ForEach(searchResults) { song in
                Button {
                    selectSong(song)
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(song.title)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Text(song.artist)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        if let album = song.album {
                            Text(album)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Song Details Section
    
    private func songDetailsSection(song: Song) -> some View {
        Section("Song Details") {
            VStack(alignment: .leading, spacing: 12) {
                if let details = songDetails {
                    ScrollView {
                        Text(details)
                            .font(.system(.caption, design: .monospaced))
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxHeight: 300)
                } else {
                    Text("Loading details...")
                        .foregroundStyle(.secondary)
                }
                
                Button("Fetch Lyrics") {
                    fetchLyrics(for: song)
                }
                .disabled(isFetchingLyrics)
                
                if isFetchingLyrics {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Fetching lyrics...")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                if let error = lyricsError {
                    Text("Error: \(error)")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
        }
    }
    
    // MARK: - Lyrics Details Section
    
    private func lyricsDetailsSection(lyricsInfo: LyricsDebugInfo) -> some View {
        Section("Lyrics Details") {
            VStack(alignment: .leading, spacing: 12) {
                // Request URL
                Group {
                    Text("Request URL:")
                        .fontWeight(.semibold)
                    Text(lyricsInfo.requestURL)
                        .font(.system(.caption, design: .monospaced))
                        .textSelection(.enabled)
                        .padding(.bottom, 8)
                }
                
                // HTTP Status
                Group {
                    Text("HTTP Status Code:")
                        .fontWeight(.semibold)
                    Text("\(lyricsInfo.httpStatus)")
                        .font(.system(.caption, design: .monospaced))
                        .padding(.bottom, 8)
                }
                
                // Response Headers
                if !lyricsInfo.responseHeaders.isEmpty {
                    Group {
                        Text("Response Headers:")
                            .fontWeight(.semibold)
                        ScrollView {
                            Text(formatHeaders(lyricsInfo.responseHeaders))
                                .font(.system(.caption, design: .monospaced))
                                .textSelection(.enabled)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(maxHeight: 150)
                        .padding(.bottom, 8)
                    }
                }
                
                // Raw Response
                Group {
                    Text("Raw JSON Response:")
                        .fontWeight(.semibold)
                    ScrollView {
                        Text(lyricsInfo.rawResponse)
                            .font(.system(.caption, design: .monospaced))
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxHeight: 300)
                    .padding(.bottom, 8)
                }
                
                // Parsed Lyrics Data
                Group {
                    Text("Parsed Lyrics Data:")
                        .fontWeight(.semibold)
                    ScrollView {
                        Text(lyricsInfo.parsedData)
                            .font(.system(.caption, design: .monospaced))
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxHeight: 300)
                    .padding(.bottom, 8)
                }
                
                // Plain Lyrics (Free from Timestamps)
                if let plainLyrics = lyricsInfo.plainLyrics, !plainLyrics.isEmpty {
                    Group {
                        Text("Plain Lyrics (Free from Timestamps):")
                            .fontWeight(.semibold)
                        ScrollView {
                            Text(plainLyrics)
                                .font(.system(.body))
                                .textSelection(.enabled)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.vertical, 4)
                        }
                        .frame(maxHeight: 400)
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func performSearch() {
        guard !searchQuery.isEmpty else { return }
        
        isSearching = true
        searchError = nil
        searchResults = []
        selectedSong = nil
        songDetails = nil
        lyricsDetails = nil
        
        Task {
            do {
                let songs = try await appleMusicService.searchSongs(query: searchQuery, language: nil)
                await MainActor.run {
                    searchResults = songs
                    isSearching = false
                    if songs.isEmpty {
                        searchError = "No results found"
                    }
                }
            } catch {
                await MainActor.run {
                    isSearching = false
                    searchError = error.localizedDescription
                }
            }
        }
    }
    
    private func selectSong(_ song: Song) {
        selectedSong = song
        songDetails = nil
        lyricsDetails = nil
        lyricsError = nil
        
        // Generate detailed song information
        let details = generateSongDetails(song)
        songDetails = details
    }
    
    private func generateSongDetails(_ song: Song) -> String {
        var details = "Song Information:\n"
        details += "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n"
        details += "ID: \(song.id)\n"
        details += "Service ID: \(song.serviceId)\n"
        details += "Title: \(song.title)\n"
        details += "Artist: \(song.artist)\n"
        details += "Album: \(song.album ?? "N/A")\n"
        details += "Duration: \(formatDuration(song.duration))\n"
        details += "Duration (seconds): \(Int(song.duration))\n\n"
        
        details += "URLs:\n"
        details += "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
        if let albumArtURL = song.albumArtURL {
            details += "Album Art URL: \(albumArtURL.absoluteString)\n"
        } else {
            details += "Album Art URL: N/A\n"
        }

        return details
    }
    
    private func fetchLyrics(for song: Song) {
        isFetchingLyrics = true
        lyricsError = nil
        lyricsDetails = nil
        
        Task {
            do {
                // Build the request URL manually to capture it
                let durationSeconds = Int(song.duration.rounded())
                var components = URLComponents(string: "https://lrclib.net/api/get")
                var queryItems: [URLQueryItem] = [
                    URLQueryItem(name: "track_name", value: song.title),
                    URLQueryItem(name: "artist_name", value: song.artist),
                    URLQueryItem(name: "duration", value: String(durationSeconds))
                ]
                
                if let album = song.album {
                    queryItems.append(URLQueryItem(name: "album_name", value: album))
                }
                
                components?.queryItems = queryItems
                guard let url = components?.url else {
                    throw MusicError.networkError("Invalid URL")
                }
                
                // Make the request with detailed tracking
                let session = URLSession.shared
                let (data, response) = try await session.data(from: url)
                
                // Get HTTP response details
                var httpStatus = 0
                var responseHeaders: [String: String] = [:]
                
                if let httpResponse = response as? HTTPURLResponse {
                    httpStatus = httpResponse.statusCode
                    for (key, value) in httpResponse.allHeaderFields {
                        if let keyString = key as? String, let valueString = value as? String {
                            responseHeaders[keyString] = valueString
                        }
                    }
                }
                
                // Check for 404
                if httpStatus == 404 {
                    throw MusicError.lyricsNotFound
                }
                
                // Validate response
                guard (200...299).contains(httpStatus) else {
                    throw MusicError.invalidResponse
                }
                
                // Decode response
                let lrcResponse = try JSONDecoder().decode(LRCLibResponse.self, from: data)
                let lyrics = lrcResponse.toSongLyrics()
                
                // Get raw JSON string
                let rawJSON = try JSONSerialization.jsonObject(with: data, options: [])
                let prettyJSON = try JSONSerialization.data(withJSONObject: rawJSON, options: .prettyPrinted)
                let rawJSONString = String(data: prettyJSON, encoding: .utf8) ?? "Unable to format JSON"
                
                // Generate parsed data string
                let parsedData = generateParsedLyricsData(lrcResponse: lrcResponse, lyrics: lyrics)
                
                let debugInfo = LyricsDebugInfo(
                    requestURL: url.absoluteString,
                    httpStatus: httpStatus,
                    responseHeaders: responseHeaders,
                    rawResponse: rawJSONString,
                    parsedData: parsedData,
                    plainLyrics: lyrics.plainLyrics
                )
                
                await MainActor.run {
                    lyricsDetails = debugInfo
                    isFetchingLyrics = false
                }
            } catch {
                await MainActor.run {
                    lyricsError = error.localizedDescription
                    isFetchingLyrics = false
                }
            }
        }
    }
    
    private func generateParsedLyricsData(lrcResponse: LRCLibResponse, lyrics: SongLyrics) -> String {
        var data = "Parsed Lyrics Data:\n"
        data += "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n"
        
        data += "LRCLib Response:\n"
        data += "  ID: \(lrcResponse.id?.description ?? "N/A")\n"
        data += "  Track Name: \(lrcResponse.trackName ?? "N/A")\n"
        data += "  Artist Name: \(lrcResponse.artistName ?? "N/A")\n"
        data += "  Album Name: \(lrcResponse.albumName ?? "N/A")\n"
        data += "  Duration: \(lrcResponse.duration?.description ?? "N/A") seconds\n"
        data += "  Instrumental: \(lrcResponse.instrumental)\n\n"
        
        data += "SongLyrics Model:\n"
        data += "  Has Lyrics: \(lyrics.hasLyrics)\n"
        data += "  Instrumental: \(lyrics.instrumental)\n"
        data += "  Plain Lyrics Available: \(lyrics.plainLyrics != nil)\n"
        data += "  Synced Lyrics Available: \(lyrics.syncedLyrics != nil)\n"
        
        if let plainLyrics = lyrics.plainLyrics {
            let preview = String(plainLyrics.prefix(200))
            data += "\n  Plain Lyrics Preview (first 200 chars):\n"
            data += "  \(preview)\n"
            if plainLyrics.count > 200 {
                data += "  ... (total: \(plainLyrics.count) characters)\n"
            }
        }
        
        if let syncedLyrics = lyrics.syncedLyrics {
            let preview = String(syncedLyrics.prefix(200))
            data += "\n  Synced Lyrics Preview (first 200 chars):\n"
            data += "  \(preview)\n"
            if syncedLyrics.count > 200 {
                data += "  ... (total: \(syncedLyrics.count) characters)\n"
            }
        }
        
        return data
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    private func formatHeaders(_ headers: [String: String]) -> String {
        return headers.map { "\($0.key): \($0.value)" }
            .joined(separator: "\n")
    }
}

// MARK: - Lyrics Debug Info

private struct LyricsDebugInfo {
    let requestURL: String
    let httpStatus: Int
    let responseHeaders: [String: String]
    let rawResponse: String
    let parsedData: String
    let plainLyrics: String?
}
#endif

