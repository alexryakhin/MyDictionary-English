import Foundation
import AVFoundation

struct SpeechSynthesizer {

    static let shared = SpeechSynthesizer()

    private let speechSynthesizer = AVSpeechSynthesizer()

    private init() {}

    func speak(_ text: String) {
        guard !speechSynthesizer.isSpeaking else { return }
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        speechSynthesizer.speak(utterance)
    }
}
