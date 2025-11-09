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
        case beginSeek
        case endSeek(TimeInterval)
        case generateLesson
    }

    enum LessonState: Hashable {
        case loading
        case ready(AdaptedLesson, MusicDiscoveringSession)
        case failed(String)
    }

    @Published private(set) var song: Song
    @Published private(set) var lyrics: SongLyrics
    @Published private(set) var parsedSyncedLines: [LyricLine] = []
    @Published private(set) var currentTime: TimeInterval = 0
    @Published private(set) var duration: TimeInterval = 0
    @Published private(set) var currentLineIndex: Int?
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
        self.parsedSyncedLines = parseSyncedLyrics(lyrics.syncedLyrics.orEmpty)
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
        case .beginSeek:
            beginSeek()
        case .endSeek(let time):
            endSeek(to: time)
        case .generateLesson:
            Task {
                await generateLesson()
            }
        }
    }
    
    private func setupBindings() {
        musicPlayerService.$currentTime
            .receive(on: DispatchQueue.main)
            .assign(to: &$currentTime)

        musicPlayerService.$duration
            .receive(on: DispatchQueue.main)
            .assign(to: &$duration)
        
        musicPlayerService.$isPlaying
            .receive(on: DispatchQueue.main)
            .assign(to: &$isPlaying)

        $currentTime
            .receive(on: DispatchQueue.main)
            .map { [weak self] time in
                guard let self, parsedSyncedLines.isNotEmpty else { return nil }
                for index in parsedSyncedLines.indices where isLineCurrent(index) {
                    return index
                }
                return nil
            }
            .assign(to: &$currentLineIndex)
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
    
    private func beginSeek() {
        musicPlayerService.startSeeking()
    }
    
    private func endSeek(to time: TimeInterval) {
        musicPlayerService.finishSeeking(to: time)
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

    private func parseSyncedLyrics(_ lyrics: String) -> [LyricLine] {
        var lines: [LyricLine] = []
        let pattern = #"\[(\d{2}):(\d{2})\.(\d{2})\](.*)"#
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        let nsString = lyrics as NSString
        let matches = regex?.matches(in: lyrics, options: [], range: NSRange(location: 0, length: nsString.length)) ?? []
        for match in matches where match.numberOfRanges >= 4 {
            let minutes = Int(nsString.substring(with: match.range(at: 1))) ?? 0
            let seconds = Int(nsString.substring(with: match.range(at: 2))) ?? 0
            let centiseconds = Int(nsString.substring(with: match.range(at: 3))) ?? 0
            let text = nsString.substring(with: match.range(at: 4)).trimmingCharacters(in: .whitespaces)
            guard text.isNotEmpty else { continue }
            let timestamp = TimeInterval(minutes * 60 + seconds) + TimeInterval(centiseconds) / 100.0
            lines.append(LyricLine(text: text, timestamp: timestamp))
        }
        return lines
    }

    private func isLineCurrent(_ index: Int) -> Bool {
        guard index < parsedSyncedLines.count else { return false }
        let line = parsedSyncedLines[index]
        let nextTimestamp = index + 1 < parsedSyncedLines.count ? parsedSyncedLines[index + 1].timestamp : .infinity
        return currentTime >= line.timestamp && currentTime < nextTimestamp
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
