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
final class SongPlayerViewModel: BaseViewModel {

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
    @Published var currentTime: TimeInterval = 0
    @Published var isSeeking: Bool = false {
        willSet {
            if newValue == false {
                musicPlayerService.seek(to: currentTime)
            }
        }
    }

    @Published private(set) var song: Song
    @Published private(set) var lyrics: SongLyrics
    @Published private(set) var parsedSyncedLines: [LyricLine] = []
    @Published private(set) var duration: TimeInterval = 0
    @Published private(set) var currentLineIndex: Int?
    @Published private(set) var isPlaying: Bool = false
    @Published private(set) var sessionIsActive: Bool = false
    @Published private(set) var lessonState: LessonState = .loading

    private let musicPlayerService = MusicPlayerService.shared
    private let lessonService = MusicLessonService.shared
    private let historyService = MusicListeningHistoryService.shared
    private let songLessonSessionService = SongLessonSessionService.shared
    private let analytics = AnalyticsService.shared
    
    private var cancellables = Set<AnyCancellable>()
    
    init(song: Song, lyrics: SongLyrics) {
        self.song = song
        self.lyrics = lyrics
        super.init()
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
        case .generateLesson:
            Task {
                await generateLesson()
            }
        }
    }
    
    private func setupBindings() {
        musicPlayerService.$currentTime
            .receive(on: DispatchQueue.main)
            .sink { [weak self] time in
                guard let self else { return }
                if !isSeeking {
                    currentTime = time
                }

                if parsedSyncedLines.isNotEmpty {
                    for index in parsedSyncedLines.indices where isLineCurrent(index) {
                        currentLineIndex = index
                    }
                }
            }
            .store(in: &cancellables)

        musicPlayerService.$duration
            .receive(on: DispatchQueue.main)
            .assign(to: &$duration)
        
        musicPlayerService.$isPlaying
            .receive(on: DispatchQueue.main)
            .assign(to: &$isPlaying)
        
        musicPlayerService.$sessionIsActive
            .receive(on: DispatchQueue.main)
            .assign(to: &$sessionIsActive)
    }
    
    private func loadData() {
        // Start playback
        Task {
            do {
                try await musicPlayerService.play(song: song)
            } catch {
                errorReceived(error)
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
        isSeeking = false
    }
    
    private func seek(to time: TimeInterval) {
        currentTime = time
        musicPlayerService.seek(to: time)
    }

    private func generateLesson() async {
        let requestStart = Date()
        let hasLyrics = lyrics.hasLyrics
        let canRequestAI = AIService.shared.canMakeAIRequest()
        
        var requestParameters: [String: Any] = [
            "song_id": song.serviceId,
            "has_lyrics": hasLyrics ? 1 : 0,
            "ai_available": canRequestAI ? 1 : 0
        ]
        if let detectedLanguage = lyrics.detectedLanguage?.rawValue {
            requestParameters["detected_language"] = detectedLanguage
        }
        analytics.logEvent(.musicDiscoveringLessonGenerationRequested, parameters: requestParameters)
        
        guard hasLyrics, canRequestAI else {
            logError("\(#file) Unable to generate lesson")
            self.lessonState = .failed(Loc.MusicDiscovering.Player.Lesson.unavailable)
            analytics.logEvent(
                .musicDiscoveringLessonGenerationFailed,
                parameters: [
                    "song_id": song.serviceId,
                    "reason": hasLyrics ? "ai_unavailable" : "lyrics_unavailable",
                    "duration_ms": Int(Date().timeIntervalSince(requestStart) * 1000)
                ]
            )
            return
        }

        if let cached = await cachedLesson() {
            await MainActor.run {
                self.lessonState = .ready(cached.lesson, cached.session)
            }
            analytics.logEvent(
                .musicDiscoveringLessonGenerationCompleted,
                parameters: [
                    "song_id": song.serviceId,
                    "source": "cache",
                    "duration_ms": Int(Date().timeIntervalSince(requestStart) * 1000)
                ]
            )
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

            let questionCount = adaptedLesson.quiz.fillInBlanks.count + adaptedLesson.quiz.meaningMCQ.count
            analytics.logEvent(
                .musicDiscoveringLessonGenerationCompleted,
                parameters: [
                    "song_id": song.serviceId,
                    "source": "network",
                    "duration_ms": Int(Date().timeIntervalSince(requestStart) * 1000),
                    "quiz_question_count": questionCount
                ]
            )
        } catch {
            await MainActor.run {
                logError("\(#file) Unable to generate lesson with error: \(error)")
                self.lessonState = .failed(error.localizedDescription)
            }
            analytics.logEvent(
                .musicDiscoveringLessonGenerationFailed,
                parameters: [
                    "song_id": song.serviceId,
                    "reason": "generation_error",
                    "error_message": error.localizedDescription,
                    "duration_ms": Int(Date().timeIntervalSince(requestStart) * 1000)
                ]
            )
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
