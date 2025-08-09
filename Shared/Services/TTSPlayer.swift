//
//  TTSPlayer.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/9/25.
//

import Foundation
import AVFoundation
import SwiftUI

final class TTSPlayer: ObservableObject {

    static let shared = TTSPlayer()

    private var player: AVAudioPlayer?
    @AppStorage(UDKeys.selectedEnglishAccent) private var selectedEnglishAccent: EnglishAccent = .american

    private init() {}

    func play(_ text: String, targetLanguage: String?) async throws(CoreError) {
        guard text.isNotEmpty, player == nil || !player!.isPlaying else { return }

        var tl: String?
        if targetLanguage == nil || targetLanguage == "en" {
            tl = selectedEnglishAccent.localeCode
        } else {
            tl = targetLanguage
        }

        let escapedText = text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "https://translate.google.com/translate_tts?ie=UTF-8&client=tw-ob&q=\(escapedText)&tl=\(tl ?? selectedEnglishAccent.localeCode)"
        guard let url = URL(string: urlString) else { return }

        guard player?.isPlaying == false || player == nil else { return }

        #if os(iOS)
        let _ = try setupAudioSession()
        #endif
        let temporaryDownloadURL = try await temporaryDownloadURL(for: url)
        try await play(from: temporaryDownloadURL)
    }

    #if os(iOS)
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
    #endif

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
