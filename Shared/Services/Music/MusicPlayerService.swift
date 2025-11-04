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

#if canImport(MusicKit)
import MusicKit
#endif

#if os(iOS)
import MediaPlayer
#endif

final class MusicPlayerService: NSObject, ObservableObject {
    static let shared = MusicPlayerService()
    
    // MARK: - Published Properties
    
    @Published var currentSong: Song?
    @Published var isPlaying = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var volume: Float = 1.0
    @Published var playbackRate: Float = 1.0
    
    // MARK: - Private Properties
    
    private var player: AVPlayer?
    private var playerItem: AVPlayerItem?
    private var timeObserver: Any?
    private let session = AVAudioSession.sharedInstance()
    
    #if canImport(MusicKit)
    private var musicPlayer: ApplicationMusicPlayer?
    #endif
    
    private var cancellables = Set<AnyCancellable>()
    
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
        // Stop current playback if any
        stop()
        
        currentSong = song
        
        switch song.serviceType {
        case .appleMusic:
            try await playAppleMusic(song: song)
        case .spotify:
            try await playSpotify(song: song)
        }
        
        await MainActor.run {
            isPlaying = true
        }
        
        updateNowPlayingInfo()
    }
    
    /// Play current song (resume if paused)
    func play() {
        Task { @MainActor in
            if let player = player {
                player.play()
                isPlaying = true
            }
            
            #if canImport(MusicKit)
            if let musicPlayer = musicPlayer {
                Task {
                    try? await musicPlayer.play()
                    await MainActor.run {
                        self.isPlaying = true
                    }
                }
            }
            #endif
        }
    }
    
    /// Pause playback
    func pause() {
        Task { @MainActor in
            player?.pause()
            
            #if canImport(MusicKit)
            Task {
                try? await musicPlayer?.pause()
            }
            #endif
            
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
            
            #if canImport(MusicKit)
            musicPlayer?.stop()
            musicPlayer = nil
            #endif
            
            currentSong = nil
            isPlaying = false
            currentTime = 0
            duration = 0
            
            removeTimeObserver()
            updateNowPlayingInfo()
        }
    }
    
    /// Seek to a specific time
    /// - Parameter time: Time in seconds
    /// Note: Seeking is only supported for Spotify preview playback, not for Apple Music
    func seek(to time: TimeInterval) {
        Task { @MainActor in
            let cmTime = CMTime(seconds: time, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
            
            // Only AVPlayer (Spotify) supports seeking
            // ApplicationMusicPlayer (Apple Music) doesn't have a seek method
            if let player = player {
                player.seek(to: cmTime)
                currentTime = time
                updateNowPlayingInfo()
            }
            
            // For Apple Music, we can only update the currentTime tracking
            // but can't actually seek in the player
            #if canImport(MusicKit)
            if musicPlayer != nil {
                // ApplicationMusicPlayer doesn't support seeking
                // Just update our tracking
                currentTime = time
                updateNowPlayingInfo()
            }
            #endif
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
            
            #if canImport(MusicKit)
            // MusicKit volume is controlled by system
            #endif
        }
    }
    
    // MARK: - Private Methods
    
    private func playAppleMusic(song: Song) async throws {
        #if canImport(MusicKit)
        let musicPlayer = ApplicationMusicPlayer.shared.queue
        
        // Search for the song in Apple Music catalog
        let searchRequest = MusicCatalogSearchRequest(term: "\(song.title) \(song.artist)", types: [MusicKit.Song.self])
        let response = try await searchRequest.response()
        
        guard let musicKitSong = response.songs.first else {
            throw MusicError.songNotFound
        }
        
        let queue = ApplicationMusicPlayer.Queue(for: [musicKitSong], startingAt: musicKitSong)
        ApplicationMusicPlayer.shared.queue = queue
        
        self.musicPlayer = ApplicationMusicPlayer.shared
        try await ApplicationMusicPlayer.shared.play()
        
        duration = song.duration
        #else
        throw MusicError.serviceUnavailable
        #endif
    }
    
    private func playSpotify(song: Song) async throws {
        guard let previewURL = song.previewURL else {
            throw MusicError.playbackNotSupported
        }
        
        let playerItem = AVPlayerItem(url: previewURL)
        self.playerItem = playerItem
        
        let newPlayer = AVPlayer(playerItem: playerItem)
        newPlayer.volume = volume
        newPlayer.rate = playbackRate
        
        // Observe playback end
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playerDidFinishPlaying),
            name: .AVPlayerItemDidPlayToEndTime,
            object: playerItem
        )
        
        // Load duration using modern async API
        Task {
            do {
                let duration = try await playerItem.asset.load(.duration)
                await MainActor.run {
                    self.duration = duration.seconds
                    self.updateNowPlayingInfo()
                }
            } catch {
                // Fallback to song duration if loading fails
                await MainActor.run {
                    self.duration = song.duration
                }
            }
        }
        
        newPlayer.play()
        self.player = newPlayer
        
        duration = song.duration
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
        // Update current time periodically
        let interval = CMTime(seconds: 0.1, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserver = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self = self else { return }
            self.currentTime = time.seconds
            self.updateNowPlayingInfo()
        }
    }
    
    private func removeTimeObserver() {
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
            timeObserver = nil
        }
    }
    
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
    }
    #else
    private func updateNowPlayingInfo() {
        // macOS implementation if needed
    }
    #endif
    
    deinit {
        removeTimeObserver()
        NotificationCenter.default.removeObserver(self)
    }
}

#if os(iOS)
import UIKit
#endif

