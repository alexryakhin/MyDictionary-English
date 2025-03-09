//
//  SpeechSynthesizer.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/9/25.
//

import Foundation
import AVFoundation

public protocol SpeechSynthesizerInterface {
    func speak(_ text: String)
}

public final class SpeechSynthesizer: SpeechSynthesizerInterface {

    private let speechSynthesizer = AVSpeechSynthesizer()

    public init() {}

    public func speak(_ text: String) {
        guard !speechSynthesizer.isSpeaking else { return }
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        speechSynthesizer.speak(utterance)
    }
}
