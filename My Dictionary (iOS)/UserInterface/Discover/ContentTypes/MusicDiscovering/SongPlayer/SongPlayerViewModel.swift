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

    enum LessonState: Hashable {
        case loading
        case ready(AdaptedLesson, MusicDiscoveringSession)
        case failed(String)
    }

    let song: Song
    let lyrics: SongLyrics

    @Published private(set) var currentTime: TimeInterval = 0
    @Published private(set) var duration: TimeInterval = 0
    @Published private(set) var isPlaying: Bool = false
    @Published private(set) var lessonState: LessonState = .loading

    private let musicPlayerService = MusicPlayerService.shared
    private let lessonService = MusicLessonService.shared
    private let historyService = MusicListeningHistoryService.shared
    private let songLessonSessionService = SongLessonSessionService.shared
    
    private var cancellables = Set<AnyCancellable>()
    
    init(song: Song, lyrics: SongLyrics) {
        self.song = song
        self.lyrics = lyrics
        setupBindings()
        loadData()
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

        // Load lesson
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
        guard lyrics.hasLyrics, AIService.shared.canMakeAIRequest() else {
            logError("\(#file) Unable to generate lesson")
            self.lessonState = .failed("Unable to generate lesson")
            return
        }

        if let cached = await cachedLesson() {
            await MainActor.run {
                self.lessonState = .ready(cached.lesson, cached.session)
            }
            return
        }

        await MainActor.run {
            self.lessonState = .loading
        }
        
        do {
            let adaptedLesson = try await lessonService.getLesson(
                for: song,
                lyrics: lyrics
            )
            let session = MusicDiscoveringSession(song: song)

            try await songLessonSessionService.saveOrUpdateSession(
                session,
                lesson: adaptedLesson,
                song: song
            )
            
            await MainActor.run {
                self.lessonState = .ready(adaptedLesson, session)
            }
        } catch {
            await MainActor.run {
                logError("\(#file) Unable to generate lesson with error: \(error)")
                self.lessonState = .failed(error.localizedDescription)
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

extension SongPlayerViewModel {
    func formatTime(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    var hasLyrics: Bool {
        lyrics.hasLyrics
    }
}
