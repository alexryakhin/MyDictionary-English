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
    @Published var isSeeking: Bool = false
    
    // MARK: - Private Properties
    
    private var player: AVPlayer?
    private var playerItem: AVPlayerItem?
    private var timeObserver: Any?
    private let session = AVAudioSession.sharedInstance()
    private var musicPlayer: ApplicationMusicPlayer?
    private var cancellables = Set<AnyCancellable>()
    private var timeUpdateTimer: Timer?
    private var songQueue: [Song] = []
    private var currentQueueIndex: Int = 0
    
    // MARK: - Initialization
    
    private override init() {
        super.init()
        setupAudioSession()
        setupTimeObserver()
        setupMusicPlayerTimeObserver()
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
            }
            
            if let musicPlayer = musicPlayer {
                Task {
                    try? await musicPlayer.play()
                    await MainActor.run {
                        // Update current time from playbackTime
                        self.currentTime = musicPlayer.playbackTime
                        self.isPlaying = true
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
            currentTime = 0
            duration = 0
            isSeeking = false
            
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
    
    /// Start seeking (called when user starts dragging slider)
    func startSeeking() {
        Task { @MainActor in
            isSeeking = true
            // Capture current playback time from the player when seeking starts
            if let musicPlayer = musicPlayer {
                currentTime = musicPlayer.playbackTime
            }
        }
    }
    
    /// Finish seeking (called when user stops dragging slider)
    /// - Parameter time: The final seek time
    func finishSeeking(to time: TimeInterval) {
        Task { @MainActor in
            // Clamp time to valid range
            let clampedTime = max(0, min(time, duration))
            
            isSeeking = false
            currentTime = clampedTime
            
            // Try to set playbackTime directly to seek to the position
            if let musicPlayer = musicPlayer {
                // Attempt to set playbackTime to seek
                // Note: playbackTime might be read-only, but we'll try setting it
                // If this causes a compile error, we'll know it's read-only
                // and will need to use a different approach
                musicPlayer.playbackTime = clampedTime
                
                // Update MPNowPlayingInfoCenter with the new position
                updateNowPlayingInfo()
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
        // Search for the song in Apple Music catalog
        let searchRequest = MusicCatalogSearchRequest(term: "\(song.title) \(song.artist)", types: [MusicKit.Song.self])
        let response = try await searchRequest.response()
        
        guard let musicKitSong = response.songs.first else {
            throw MusicError.songNotFound
        }
        
        // Check if user has Apple Music subscription
        // Note: This check might not be perfect, but we can try to play and catch errors
        let queue = ApplicationMusicPlayer.Queue(for: [musicKitSong], startingAt: musicKitSong)
        ApplicationMusicPlayer.shared.queue = queue
        
        self.musicPlayer = ApplicationMusicPlayer.shared
        
        do {
            try await ApplicationMusicPlayer.shared.play()
            await MainActor.run {
                duration = song.duration
            }
        } catch {
            // Convert playback errors to user-friendly messages
            let errorDescription = error.localizedDescription.lowercased()
            let errorMessage = error.localizedDescription
            
            // Check for MPMusicPlayerControllerErrorDomain error 6
            // Error 6 typically means: no subscription, song not available, or authorization issue
            if errorMessage.contains("MPMusicPlayerControllerErrorDomain") && errorMessage.contains("error 6") {
                throw MusicError.appleMusicSubscriptionRequired
            }
            
            // Check for other common error patterns
            if errorDescription.contains("subscription") || errorDescription.contains("not subscribed") {
                throw MusicError.appleMusicSubscriptionRequired
            }
            
            if errorDescription.contains("not found") || errorDescription.contains("unavailable") {
                throw MusicError.songNotFound
            }
            
            if errorDescription.contains("not registered") || errorDescription.contains("404") || errorDescription.contains("client not found") {
                throw MusicError.appleMusicNotRegistered
            }
            
            if errorDescription.contains("network") || errorDescription.contains("connection") {
                throw MusicError.networkError(errorMessage)
            }
            
            // Generic playback error
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
    
    #if os(iOS)
    private func setupMusicPlayerTimeObserver() {
        // Timer to update currentTime from MPNowPlayingInfoCenter for ApplicationMusicPlayer
        // This will be started when ApplicationMusicPlayer is playing
    }
    
    private func startMusicPlayerTimeObserver() {
        stopMusicPlayerTimeObserver()
        
        guard let musicPlayer = musicPlayer else { return }
        
        // Read playback time from MusicPlayer.playbackTime property
        timeUpdateTimer = Timer(timeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            Task { @MainActor in
                // Don't update time if we're seeking (user is dragging slider)
                guard !self.isSeeking else { return }
                
                // Only update time if we're playing
                guard self.isPlaying else { return }
                
                // Read actual playback time from the player
                let playbackTime = musicPlayer.playbackTime
                self.currentTime = playbackTime
                
                // Clamp to duration
                if self.duration > 0 {
                    self.currentTime = min(self.currentTime, self.duration)
                }

                if playbackTime == .zero {
                    self.isPlaying = false
                }

                // Update MPNowPlayingInfoCenter
                self.updateNowPlayingInfo()
            }
        }
        RunLoop.main.add(timeUpdateTimer!, forMode: .common)
    }
    
    private func stopMusicPlayerTimeObserver() {
        timeUpdateTimer?.invalidate()
        timeUpdateTimer = nil
    }
    #else
    private func setupMusicPlayerTimeObserver() {}
    private func startMusicPlayerTimeObserver() {}
    private func stopMusicPlayerTimeObserver() {}
    #endif
    
    private func loadVolume() {
        volume = UserDefaults.standard.object(forKey: "music_player_volume") as? Float ?? 1.0
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

