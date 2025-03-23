//
//  TTSPlayer.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/9/25.
//

import Foundation
import AVFoundation
import Core

public protocol TTSPlayerInterface {
    func play(_ text: String) async throws(CoreError)
}

public final class TTSPlayer: TTSPlayerInterface {

    private var player: AVAudioPlayer?
    private var selectedTTLLanguage: TTSLanguage {
        guard let languageCode = UserDefaults.standard.string(forKey: UDKeys.selectedTTSLanguage) else {
            return .enUS
        }
        return TTSLanguage(rawValue: languageCode) ?? .enUS
    }

    public init() {}

    public func play(_ text: String) async throws(CoreError) {
        guard text.isNotEmpty else { return }

        let escapedText = text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "https://translate.google.com/translate_tts?ie=UTF-8&client=tw-ob&q=\(escapedText)&tl=\(selectedTTLLanguage.rawValue)"
        guard let url = URL(string: urlString) else { return }

        guard player?.isPlaying == false || player == nil else { return }

        let _ = try setupAudioSession()
        let temporaryDownloadURL = try await temporaryDownloadURL(for: url)
        try await play(from: temporaryDownloadURL)
    }

    private func setupAudioSession() throws(CoreError) -> AVAudioSession {
        let session = AVAudioSession.sharedInstance()
        do {    
            try session.setCategory(.playback)
            try session.setActive(true)
            return session
        } catch {
            throw .internalError(.cannotSetupAudioSession)
        }
    }

    private func temporaryDownloadURL(for url: URL) async throws(CoreError) -> URL {
        let request = URLRequest(url: url, cachePolicy: .useProtocolCachePolicy)

        do {
            let (url, _) = try await URLSession.shared.download(for: request)
            return url
        } catch {
            throw CoreError.networkError(.noData)
        }
    }

    @MainActor
    private func play(from url: URL) throws(CoreError) {
        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.prepareToPlay()
            player?.play()
        } catch {
            throw .internalError(.cannotPlayAudio)
        }
    }
}
