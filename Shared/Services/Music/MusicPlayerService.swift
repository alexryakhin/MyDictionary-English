//
//  MusicPlayerService.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin
//

import Foundation
import AVFoundation
import SwiftUI
import Combine
import MusicKit
import MediaPlayer

final class MusicPlayerService: NSObject, ObservableObject {
    static let shared = MusicPlayerService()
    
    // MARK: - Published Properties
    
    @Published var currentSong: Song?
    @Published var isPlaying = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var volume: Float = 1.0
    @Published var playbackRate: Float = 1.0
    @Published var sessionIsActive: Bool = false

    // MARK: - Private Properties
    
    private var player: AVPlayer?
    private var playerItem: AVPlayerItem?
    private var timeObserver: Any?
    private var musicPlayer: ApplicationMusicPlayer?
    private var cancellables = Set<AnyCancellable>()
    private var timeUpdateTimer: Timer?
    private var songQueue: [Song] = []
    private var currentQueueIndex: Int = 0
    private var playbackStallCounter: Int = 0
    private var lastObservedPlaybackTime: TimeInterval = 0

    #if os(iOS)
    private let session = AVAudioSession.sharedInstance()
    #endif

    // MARK: - Initialization
    
    private override init() {
        super.init()
        setupAudioSession()
        setupTimeObserver()
        loadVolume()
        #if os(iOS)
        setupRemoteCommandCenter()
        #endif
    }
    
    // MARK: - Public Methods
    
    /// Play a song
    /// - Parameter song: The song to play
    func play(song: Song) async throws {
        // Set current song first (before stopping, so it's not cleared)
        await MainActor.run {
            currentSong = song
        }

        // Stop current playback if any
        stop()
        
        // Re-set current song after stop() (in case stop() cleared it)
        await MainActor.run {
            currentSong = song
        }

        try await playAppleMusic(song: song)
        
        await MainActor.run {
            isPlaying = true
            currentTime = 0
            sessionIsActive = true
            resetPlaybackMonitoring()
        }
        
        updateNowPlayingInfo()
        startMusicPlayerTimeObserver()
    }
    
    /// Set the queue of songs for navigation
    /// - Parameter songs: Array of songs to queue
    /// - Parameter currentIndex: Index of the currently playing song
    func setQueue(_ songs: [Song], currentIndex: Int = 0) {
        Task { @MainActor in
            self.songQueue = songs
            self.currentQueueIndex = max(0, min(currentIndex, songs.count - 1))
        }
    }
    
    /// Skip to next song in queue
    func skipToNext() async throws {
        guard !songQueue.isEmpty, currentQueueIndex < songQueue.count - 1 else {
            return
        }
        
        let nextIndex = currentQueueIndex + 1
        let nextSong = songQueue[nextIndex]
        currentQueueIndex = nextIndex
        
        try await play(song: nextSong)
    }
    
    /// Skip to previous song in queue
    func skipToPrevious() async throws {
        guard !songQueue.isEmpty else {
            // If no queue, just seek to beginning
            seek(to: 0)
            return
        }
        
        if currentQueueIndex > 0 {
            let previousIndex = currentQueueIndex - 1
            let previousSong = songQueue[previousIndex]
            currentQueueIndex = previousIndex
            
            try await play(song: previousSong)
        } else {
            // If at first song, seek to beginning
            seek(to: 0)
        }
    }
    
    /// Play current song (resume if paused)
    func play() {
        Task { @MainActor in
            if let player = player {
                player.play()
                isPlaying = true
                playbackStallCounter = 0
                lastObservedPlaybackTime = currentTime
            }
            
            if let musicPlayer = musicPlayer {
                Task {
                    try? await musicPlayer.play()
                    await MainActor.run {
                        // Update current time from playbackTime
                        self.currentTime = musicPlayer.playbackTime
                        self.isPlaying = true
                        self.playbackStallCounter = 0
                        self.lastObservedPlaybackTime = self.currentTime
                    }
                }
            }
        }
    }
    
    /// Pause playback
    func pause() {
        Task { @MainActor in
            player?.pause()
            if let musicPlayer = musicPlayer {
                musicPlayer.pause()
                // Update current time from playbackTime
                currentTime = musicPlayer.playbackTime
            }
            isPlaying = false
            playbackStallCounter = 0
            lastObservedPlaybackTime = currentTime
        }
    }
    
    /// Stop playback
    func stop() {
        Task { @MainActor in
            player?.pause()
            player?.seek(to: .zero)
            player = nil
            playerItem = nil
            
            musicPlayer?.stop()
            musicPlayer = nil
            
            currentSong = nil
            isPlaying = false
            sessionIsActive = false
            currentTime = 0
            duration = 0
            resetPlaybackMonitoring()

            removeTimeObserver()
            stopMusicPlayerTimeObserver()
            updateNowPlayingInfo()
        }
    }
    
    /// Seek to a specific time
    /// - Parameter time: Time in seconds
    func seek(to time: TimeInterval) {
        Task { @MainActor in
            // Clamp time to valid range
            let clampedTime = max(0, min(time, duration))
            
            // Update current time for UI responsiveness
            currentTime = clampedTime
            lastObservedPlaybackTime = clampedTime
            
            // Actually seek the music player
            if let musicPlayer = musicPlayer {
                musicPlayer.playbackTime = clampedTime
                updateNowPlayingInfo()
            }
            
            // Seek AVPlayer if available
            if let player = player {
                player.seek(to: CMTime(seconds: clampedTime, preferredTimescale: 600))
            }
        }
    }

    /// Set volume
    /// - Parameter volume: Volume level (0.0 to 1.0)
    func setVolume(_ volume: Float) {
        Task { @MainActor in
            self.volume = max(0.0, min(1.0, volume))
            player?.volume = self.volume
            
            // Save volume preference
            UserDefaults.standard.set(self.volume, forKey: "music_player_volume")
            
            // MusicKit volume is controlled by system
        }
    }
    
    // MARK: - Private Methods
    
    private func playAppleMusic(song: Song) async throws {

        var musicKitSong: MusicKit.Song?

        let catalogRequest = MusicCatalogResourceRequest<MusicKit.Song>(matching: \.id, equalTo: MusicItemID(song.id))
        musicKitSong = try? await catalogRequest.response().items.first

        if musicKitSong == nil {
            // Search for the song in Apple Music catalog
            logWarning("[MusicPlayerService] Song \(song) not found by ID, searching by title and artist")
            let searchRequest = MusicCatalogSearchRequest(term: "\(song.title) \(song.artist)", types: [MusicKit.Song.self])
            musicKitSong = try? await searchRequest.response().songs.filter({ $0.contentRating != .explicit }).first
        }

        guard let musicKitSong else {
            logError("[MusicPlayerService] Song \(song) not found in Apple Music catalog")
            throw MusicError.songNotFound
        }

        logSuccess("[MusicPlayerService] Song \(song) has been found in Apple Music catalog, musicKitSong: \(musicKitSong)")

        // Check if user has Apple Music subscription
        // Note: This check might not be perfect, but we can try to play and catch errors
        let queue = ApplicationMusicPlayer.Queue(for: [musicKitSong], startingAt: musicKitSong)
        ApplicationMusicPlayer.shared.queue = queue
        
        self.musicPlayer = ApplicationMusicPlayer.shared

        let retryDelays: [TimeInterval] = [0, 1, 2, 3]
        var lastError: Error?

        for (attemptIndex, delay) in retryDelays.enumerated() {
            if delay > 0 {
                let nanoDelay = UInt64(delay * 1_000_000_000)
                try await Task.sleep(nanoseconds: nanoDelay)
            }

            do {
                try await ApplicationMusicPlayer.shared.play()
                await MainActor.run {
                    duration = song.duration
                }
                lastError = nil
                break
            } catch {
                lastError = error
                logWarning("[MusicPlayerService] Attempt \(attemptIndex + 1) to play song \(song.id) failed with error: \(error.localizedDescription)")
            }
        }

        if let error = lastError {
            logError("[MusicPlayerService] Failed to play song \(song) with ID: \(song.id) after retries, error: \(error.localizedDescription)")
            throw MusicError.playbackNotSupported
        }
    }
    
    @objc private func playerDidFinishPlaying() {
        Task { @MainActor in
            isPlaying = false
            currentTime = 0
        }
    }
    
    private func setupAudioSession() {
        #if os(iOS)
        do {
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
        } catch {
            print("⚠️ [MusicPlayerService] Failed to setup audio session: \(error)")
        }
        #endif
    }
    
    private func setupTimeObserver() {
        // Update current time periodically for AVPlayer
        // This is set up when AVPlayer is used
    }
    
    private func removeTimeObserver() {
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
            timeObserver = nil
        }
    }

    private func startMusicPlayerTimeObserver() {
        stopMusicPlayerTimeObserver()
        
        timeUpdateTimer = Timer(timeInterval: 0.15, repeats: true) { [weak self] _ in
            guard let self else { return }
            
            Task { @MainActor in
                guard let player = self.musicPlayer else { return }
                self.updatePlaybackProgress(with: player.playbackTime)
            }
        }
        if let timeUpdateTimer {
            RunLoop.main.add(timeUpdateTimer, forMode: .common)
        }
    }
    
    private func stopMusicPlayerTimeObserver() {
        timeUpdateTimer?.invalidate()
        timeUpdateTimer = nil
        playbackStallCounter = 0
        lastObservedPlaybackTime = 0
    }

    private func loadVolume() {
        volume = UserDefaults.standard.object(forKey: "music_player_volume") as? Float ?? 1.0
    }
    
    // MARK: - Playback Progress Helpers
    
    @MainActor
    private func updatePlaybackProgress(with playbackTime: TimeInterval) {
        let effectiveDuration = max(duration, playbackTime)
        let clampedTime = min(max(0, playbackTime), effectiveDuration)
        currentTime = clampedTime
        
        guard isPlaying else {
            playbackStallCounter = 0
            lastObservedPlaybackTime = clampedTime
            updateNowPlayingInfo()
            return
        }
        
        if abs(clampedTime - lastObservedPlaybackTime) < 0.05 {
            playbackStallCounter += 1
        } else {
            playbackStallCounter = 0
        }
        lastObservedPlaybackTime = clampedTime
        
        let nearEffectiveEnd = effectiveDuration > 0 &&
            clampedTime >= max(effectiveDuration * 0.98, effectiveDuration - 0.5)
        let stalledNearEnd = playbackStallCounter >= 5 &&
            clampedTime >= max(1, effectiveDuration * 0.9)
        
        if nearEffectiveEnd || stalledNearEnd {
            completePlayback()
        } else {
            updateNowPlayingInfo()
        }
    }
    
    @MainActor
    private func completePlayback() {
        guard isPlaying else { return }
        
        isPlaying = false
        playbackStallCounter = 0
        lastObservedPlaybackTime = 0
        musicPlayer?.pause()
        musicPlayer?.playbackTime = 0
        currentTime = 0
        updateNowPlayingInfo()
    }
    
    @MainActor
    private func resetPlaybackMonitoring() {
        playbackStallCounter = 0
        lastObservedPlaybackTime = 0
    }
    
    #if os(iOS)
    private func updateNowPlayingInfo() {
        guard let song = currentSong else {
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
            return
        }
        
        var nowPlayingInfo: [String: Any] = [
            MPMediaItemPropertyTitle: song.title,
            MPMediaItemPropertyArtist: song.artist,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: currentTime,
            MPNowPlayingInfoPropertyPlaybackRate: isPlaying ? playbackRate : 0.0
        ]
        
        if let album = song.album {
            nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = album
        }
        
        if duration > 0 {
            nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = duration
        }
        
        // Load artwork asynchronously
        if let artworkURL = song.albumArtURL {
            Task {
                if let imageData = try? await URLSession.shared.data(from: artworkURL).0,
                   let image = UIImage(data: imageData) {
                    let artwork = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
                    await MainActor.run {
                        nowPlayingInfo[MPMediaItemPropertyArtwork] = artwork
                        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
                    }
                }
            }
        } else {
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
        }
    }
    
    private func setupRemoteCommandCenter() {
        let commandCenter = MPRemoteCommandCenter.shared()
        
        commandCenter.playCommand.addTarget { [weak self] _ in
            self?.play()
            return .success
        }
        
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            self?.pause()
            return .success
        }
        
        commandCenter.togglePlayPauseCommand.addTarget { [weak self] _ in
            if self?.isPlaying == true {
                self?.pause()
            } else {
                self?.play()
            }
            return .success
        }
        
        commandCenter.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let self = self,
                  let event = event as? MPChangePlaybackPositionCommandEvent else {
                return .commandFailed
            }
            self.seek(to: event.positionTime)
            return .success
        }
        
        commandCenter.nextTrackCommand.addTarget { [weak self] _ in
            Task {
                try? await self?.skipToNext()
            }
            return .success
        }
        
        commandCenter.previousTrackCommand.addTarget { [weak self] _ in
            Task {
                try? await self?.skipToPrevious()
            }
            return .success
        }
    }
    #else
    private func updateNowPlayingInfo() {
        // macOS implementation if needed
    }
    #endif
    
    deinit {
        removeTimeObserver()
        stopMusicPlayerTimeObserver()
        NotificationCenter.default.removeObserver(self)
    }
}

#if os(iOS)
import UIKit
#endif

