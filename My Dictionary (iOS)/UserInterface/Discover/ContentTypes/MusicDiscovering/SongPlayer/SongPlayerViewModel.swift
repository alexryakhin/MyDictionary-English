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
    
    enum Input {
        case loadData
        case playPause
        case seek(to: TimeInterval)
        case generateLesson
    }
    
    let song: Song
    
    @Published private(set) var lyrics: SongLyrics?
    @Published private(set) var currentTime: TimeInterval = 0
    @Published private(set) var duration: TimeInterval = 0
    @Published private(set) var isPlaying: Bool = false
    @Published private(set) var isGeneratingLesson: Bool = false
    @Published private(set) var lessonReady: Bool = false
    @Published private(set) var adaptedLesson: AdaptedLesson?
    
    private let musicPlayerService = MusicPlayerService.shared
    private let lyricsService = LRCLibService.shared
    private let lessonService = MusicLessonService.shared
    private let historyService = MusicListeningHistoryService.shared
    
    private var cancellables = Set<AnyCancellable>()
    
    init(song: Song, lyrics: SongLyrics? = nil) {
        self.song = song
        self.lyrics = lyrics // Use provided lyrics if available
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
        if lyrics == nil {
            Task {
                do {
                    let lyrics = try await lyricsService.getLyrics(
                        trackName: song.title,
                        artistName: song.artist,
                        albumName: song.album,
                        duration: song.duration
                    )
                    await MainActor.run {
                        self.lyrics = lyrics
                    }
                } catch {
                    await MainActor.run {
                        self.lyrics = nil
                    }
                }
            }
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
        guard let lyrics = lyrics, lyrics.hasLyrics else {
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
            
            await MainActor.run {
                self.adaptedLesson = adaptedLesson
                self.isGeneratingLesson = false
                self.lessonReady = true
            }
        } catch {
            await MainActor.run {
                self.isGeneratingLesson = false
            }
        }
    }
}


