import Foundation
import AVFoundation
import Speech

@MainActor
final class PronunciationQuizRecorderViewModel: ObservableObject {

    enum PermissionsStatus {
        case unknown
        case granted
        case denied
    }

    struct LineState: Equatable {
        var transcript: String
        var isCorrect: Bool?
    }

    @Published private(set) var permissionsStatus: PermissionsStatus = .unknown
    @Published private(set) var currentLineIndex: Int = 0
    @Published private(set) var isRecording: Bool = false
    @Published private(set) var isProcessingResult: Bool = false
    @Published private(set) var liveTranscription: String = ""
    @Published private(set) var lineStates: [Int: LineState] = [:]
    @Published var errorMessage: String?

    private let config: PronunciationQuizConfig
    private var speechRecognizer: SFSpeechRecognizer?

    private var recognitionTask: SFSpeechRecognitionTask?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var audioEngine = AVAudioEngine()
    private var isFinishingAttempt: Bool = false

    init(config: PronunciationQuizConfig) {
        self.config = config
        guard let currentItem else { return }
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: currentItem.language.rawValue))
    }

    var items: [PronunciationQuizConfig.Item] {
        config.items
    }

    var currentItem: PronunciationQuizConfig.Item? {
        guard items.indices.contains(currentLineIndex) else { return nil }
        return items[currentLineIndex]
    }

    var currentState: LineState {
        lineStates[currentLineIndex] ?? LineState(transcript: "", isCorrect: nil)
    }

    var allLinesAnswered: Bool {
        items.indices.allSatisfy { lineStates[$0]?.isCorrect != nil }
    }

    var canGoToNextLine: Bool {
        currentState.isCorrect != nil && !isRecording && !isProcessingResult
    }

    func requestPermissions() async {
        guard permissionsStatus == .unknown else { return }
        let microphoneGranted = await requestMicrophonePermission()
        let speechGranted = await requestSpeechPermission()
        permissionsStatus = (microphoneGranted && speechGranted) ? .granted : .denied
    }

    func goToNextLine() {
        logInfo("[PronunciationQuizRecorderViewModel] Going to next question")
        let nextIndex = currentLineIndex + 1
        guard items.indices.contains(nextIndex) else {
            finishQuizIfNeeded()
            return
        }
        currentLineIndex = nextIndex
        liveTranscription = ""
        guard let item = items[safe: nextIndex] else { return }
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: item.language.rawValue))
    }

    func goToPreviousLine() {
        logInfo("[PronunciationQuizRecorderViewModel] Going to previous question")
        let previousIndex = currentLineIndex - 1
        guard items.indices.contains(previousIndex) else { return }
        currentLineIndex = previousIndex
        liveTranscription = currentState.transcript
        guard let item = items[safe: previousIndex] else { return }
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: item.language.rawValue))
    }

    func toggleRecording() async {
        if isRecording {
            await stopRecording()
        } else {
            await startRecording()
        }
    }

    func startRecording() async {
        guard !isRecording else { return }
        guard permissionsStatus == .granted else {
            permissionsStatus = .denied
            return
        }
        guard let recognizer = speechRecognizer, recognizer.isAvailable else {
            errorMessage = Loc.Errors.cannotSetupAudioSession
            return
        }

        resetRecognition()
        lineStates[currentLineIndex] = LineState(transcript: "", isCorrect: nil)
        liveTranscription = ""
        isProcessingResult = false

        do {
            let request = SFSpeechAudioBufferRecognitionRequest()
            request.shouldReportPartialResults = true
            recognitionRequest = request

            let inputNode = audioEngine.inputNode
            let recordingFormat = inputNode.outputFormat(forBus: 0)
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
                self?.recognitionRequest?.append(buffer)
            }

            audioEngine.prepare()
            try audioEngine.start()

            recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
                guard let self, self.isRecording else { return }

                if let result {
                    Task { @MainActor in
                        logSuccess("[PronunciationQuizRecorderViewModel] Recognition result: \(result.bestTranscription.formattedString)")
                        let spokenText = result.bestTranscription.formattedString
                        self.liveTranscription = spokenText
                        let cleanedSpoken = spokenText.trimmingCharacters(in: .whitespacesAndNewlines)
                        let isCorrect = self.evaluate(spokenText: cleanedSpoken)
                        if isCorrect {
                            await self.completeCurrentAttempt(spokenText: spokenText)
                        }
                    }
                }

                if let error {
                    Task { @MainActor in
                        self.errorMessage = error.localizedDescription
                        await self.completeCurrentAttempt(spokenText: self.liveTranscription)
                    }
                }
            }

            isRecording = true
        } catch {
            resetRecognition()
            errorMessage = error.localizedDescription
        }
    }

    func stopRecording() async {
        guard isRecording else { return }
        isRecording = false
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest?.endAudio()
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)

        let spokenSnapshot = liveTranscription
        await completeCurrentAttempt(spokenText: spokenSnapshot)
    }

    private func completeCurrentAttempt(spokenText: String) async {
        guard !isFinishingAttempt else { return }
        isFinishingAttempt = true
        isProcessingResult = true
        defer {
            isRecording = false
            isProcessingResult = false
            isFinishingAttempt = false
        }

        resetRecognition()
        let cleanedSpoken = spokenText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanedSpoken.isEmpty else {
            storeResult(transcript: "", isCorrect: false)
            return
        }

        let isCorrect = evaluate(spokenText: cleanedSpoken)
        HapticManager.shared.triggerNotification(type: isCorrect ? .success : .error)
        storeResult(transcript: cleanedSpoken, isCorrect: isCorrect)
    }

    private func storeResult(transcript: String, isCorrect: Bool) {
        lineStates[currentLineIndex] = LineState(transcript: transcript, isCorrect: isCorrect)

        guard let item = currentItem else { return }
        let submission = PronunciationQuizConfig.SubmissionItem(
            item: item,
            spokenText: transcript,
            isCorrect: isCorrect
        )
        config.onAnswer(submission)

        if allLinesAnswered {
            finishQuizIfNeeded()
        }
    }

    private func finishQuizIfNeeded() {
        guard allLinesAnswered else { return }
        let submissions: [PronunciationQuizConfig.SubmissionItem] = items.enumerated().compactMap { index, item in
            guard let state = lineStates[index], let result = state.isCorrect else { return nil }
            return PronunciationQuizConfig.SubmissionItem(
                item: item,
                spokenText: state.transcript,
                isCorrect: result
            )
        }
        config.onCompletion(submissions)
    }

    private func evaluate(spokenText: String) -> Bool {
        guard let expected = currentItem?.text else { return false }
        let normalizedSpoken = Self.normalized(text: spokenText)
        let normalizedExpected = Self.normalized(text: expected)
        return normalizedSpoken == normalizedExpected
    }

    private static func normalized(text: String) -> String {
        text
            .lowercased()
            .filter { !$0.isPunctuation && !$0.isWhitespace }
    }

    private func requestMicrophonePermission() async -> Bool {
        await withCheckedContinuation { continuation in
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                continuation.resume(returning: granted)
            }
        }
    }

    private func requestSpeechPermission() async -> Bool {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }

    private func resetRecognition() {
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil

        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }
    }
}