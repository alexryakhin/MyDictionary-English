//
//  SongPlayerViewModel.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin
//

import Foundation
import Combine
import SwiftUI

@MainActor
final class SongPlayerViewModel: ObservableObject {
    
    enum LyricsState {
        case empty
        case loading
        case content(SongLyrics)
        case error(message: String)
    }
    
    enum Input {
        case loadData
        case playPause
        case seek(to: TimeInterval)
        case generateLesson
    }
    
    let song: Song
    
    @Published private(set) var lyricsState: LyricsState
    @Published private(set) var currentTime: TimeInterval = 0
    @Published private(set) var duration: TimeInterval = 0
    @Published private(set) var isPlaying: Bool = false
    @Published private(set) var isGeneratingLesson: Bool = false
    @Published private(set) var lessonReady: Bool = false
    @Published private(set) var adaptedLesson: AdaptedLesson?
    @Published private(set) var session: MusicDiscoveringSession?
    
    private let musicPlayerService = MusicPlayerService.shared
    private let lyricsService = LRCLibService.shared
    private let lessonService = MusicLessonService.shared
    private let historyService = MusicListeningHistoryService.shared
    private let songLessonSessionService = SongLessonSessionService.shared
    
    private var cancellables = Set<AnyCancellable>()
    
    private var currentLyrics: SongLyrics? {
        guard case let .content(lyrics) = lyricsState else {
            return nil
        }
        return lyrics
    }
    
    init(song: Song, lyrics: SongLyrics? = nil) {
        self.song = song
        self.lyricsState = lyrics.map { .content($0) } ?? .empty
        setupBindings()
    }
    
    func handle(_ input: Input) {
        switch input {
        case .loadData:
            loadData()
        case .playPause:
            playPause()
        case .seek(let time):
            seek(to: time)
        case .generateLesson:
            Task {
                await generateLesson()
            }
        }
    }
    
    private func setupBindings() {
        musicPlayerService.$currentTime
            .assign(to: &$currentTime)
        
        musicPlayerService.$duration
            .assign(to: &$duration)
        
        musicPlayerService.$isPlaying
            .assign(to: &$isPlaying)
    }
    
    private func loadData() {
        // Load lyrics only if not already provided
        switch lyricsState {
        case .empty, .error:
            lyricsState = .loading
            Task {
                do {
                    let lyrics = try await lyricsService.getLyrics(
                        trackName: song.title,
                        artistName: song.artist,
                        albumName: song.album,
                        duration: song.duration
                    )
                    await MainActor.run {
                        self.lyricsState = .content(lyrics)
                    }
                    await self.generateLesson()
                } catch {
                    await MainActor.run {
                        self.lyricsState = .error(message: error.localizedDescription)
                    }
                }
            }
        case .loading, .content:
            break
        }
        
        // Start playback
        Task {
            do {
                try await musicPlayerService.play(song: song)
            } catch {
                print("Failed to play song: \(error)")
            }
        }
        
        // Save to history
        Task {
            await historyService.addToHistory(song: song)
        }
        
        // Generate lesson in background
        Task {
            await generateLesson()
        }
    }
    
    private func playPause() {
        if musicPlayerService.isPlaying {
            musicPlayerService.pause()
        } else {
            musicPlayerService.play()
        }
    }
    
    private func seek(to time: TimeInterval) {
        musicPlayerService.seek(to: time)
    }
    
    private func generateLesson() async {
        if let cached = await cachedLesson() {
            await MainActor.run {
                self.adaptedLesson = cached.lesson
                self.session = cached.session
                self.lessonReady = true
                self.isGeneratingLesson = false
            }
            return
        }
        
        guard let lyrics = currentLyrics, lyrics.hasLyrics else {
            return
        }
        
        guard AIService.shared.canMakeAIRequest() else {
            return
        }
        
        await MainActor.run {
            isGeneratingLesson = true
        }
        
        do {
            // Generate lesson (uses song's CEFR level)
            let adaptedLesson = try await lessonService.getLesson(
                for: song,
                lyrics: lyrics
            )
            var session = MusicDiscoveringSession(song: song)
            
            try await songLessonSessionService.saveOrUpdateSession(
                session,
                lesson: adaptedLesson,
                song: song
            )
            
            await MainActor.run {
                self.adaptedLesson = adaptedLesson
                self.session = session
                self.isGeneratingLesson = false
                self.lessonReady = true
            }
        } catch {
            await MainActor.run {
                self.isGeneratingLesson = false
            }
        }
    }

    private func cachedLesson() async -> (lesson: AdaptedLesson, session: MusicDiscoveringSession)? {
        await MainActor.run {
            guard let stored = songLessonSessionService.getSession(by: song.id),
                  let storedLesson = stored.lesson,
                  let storedSession = stored.toMusicDiscoveringSession() else {
                return nil
            }
            
            return (storedLesson, storedSession)
        }
    }
}