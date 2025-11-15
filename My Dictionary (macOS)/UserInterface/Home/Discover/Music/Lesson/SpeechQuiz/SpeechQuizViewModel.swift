//
//  SpeechQuizViewModel.swift
//  My Dictionary (macOS)
//
//  Created by GPT-5 Codex
//

import Foundation
import AVFoundation
import Speech

extension SongLesson {
    @MainActor
    final class SpeechQuizViewModel: ObservableObject {
        enum PermissionsStatus {
            case unknown
            case granted
            case denied
        }

        struct LineState: Equatable {
            var transcript: String
            var score: Int?
        }

        @Published private(set) var permissionsStatus: PermissionsStatus = .unknown
        @Published private(set) var currentLineIndex: Int = 0
        @Published private(set) var isRecording: Bool = false
        @Published private(set) var isProcessingResult: Bool = false
        @Published private(set) var liveTranscription: String = ""
        @Published private(set) var lineStates: [Int: LineState] = [:]

        private var isFinishingAttempt: Bool = false

        let items: [SpeechQuizItem]
        let questionIndexOffset: Int

        private let onAnswer: (QuizSubmission) -> Void
        private let onCompletion: ([QuizSubmission]) -> Void
        private let speechRecognizer: SFSpeechRecognizer?

        private var recognitionTask: SFSpeechRecognitionTask?
        private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
        private var audioEngine = AVAudioEngine()

        init(
            items: [SpeechQuizItem],
            initialAnswers: [Int: Int],
            questionIndexOffset: Int,
            localeIdentifier: String,
            initialTranscripts: [Int: String],
            onAnswer: @escaping (QuizSubmission) -> Void,
            onCompletion: @escaping ([QuizSubmission]) -> Void
        ) {
            self.items = items
            self.questionIndexOffset = questionIndexOffset
            self.onAnswer = onAnswer
            self.onCompletion = onCompletion
            self.speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: localeIdentifier))

            var initialStates: [Int: LineState] = [:]
            for (index, score) in initialAnswers {
                let normalizedScore = score == 1 ? 1 : 0
                let transcript = initialTranscripts[index] ?? ""
                initialStates[index] = LineState(transcript: transcript, score: normalizedScore)
            }
            lineStates = initialStates
        }

        var currentItem: SpeechQuizItem? {
            guard items.indices.contains(currentLineIndex) else { return nil }
            return items[currentLineIndex]
        }

        var currentState: LineState {
            if let existing = lineStates[currentLineIndex] {
                return existing
            }
            return LineState(transcript: "", score: nil)
        }

        var allLinesAnswered: Bool {
            items.indices.allSatisfy { lineStates[$0]?.score != nil }
        }

        var canGoToNextLine: Bool {
            currentState.score != nil && !isRecording && !isProcessingResult
        }

        func requestPermissions() async {
            guard permissionsStatus == .unknown else { return }
            let microphoneGranted = await requestMicrophonePermission()
            let speechGranted = await requestSpeechPermission()
            permissionsStatus = (microphoneGranted && speechGranted) ? .granted : .denied
        }

        func goToNextLine() {
            let nextIndex = currentLineIndex + 1
            guard items.indices.contains(nextIndex) else {
                finishQuizIfNeeded()
                return
            }
            currentLineIndex = nextIndex
            liveTranscription = ""
        }

        func goToPreviousLine() {
            let previousIndex = currentLineIndex - 1
            guard items.indices.contains(previousIndex) else { return }
            currentLineIndex = previousIndex
            liveTranscription = currentState.transcript
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
                logError("[SpeechQuizViewModel] Recognition error")
                return
            }

            resetRecognition()
            lineStates[currentLineIndex] = LineState(transcript: "", score: nil)
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
                    guard let self else { return }

                    if let result {
                        Task { @MainActor in
                            logSuccess("[SpeechQuizViewModel] Recognition result: \(result.bestTranscription.formattedString)")
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
                            logError("[SpeechQuizViewModel] Recognition error: \(error.localizedDescription)")
                            await self.completeCurrentAttempt(spokenText: self.liveTranscription)
                        }
                    }
                }

                isRecording = true
            } catch {
                resetRecognition()
                logError("[SpeechQuizViewModel] Recognition error: \(error.localizedDescription)")
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
            storeResult(transcript: cleanedSpoken, isCorrect: isCorrect)
        }

        private func storeResult(transcript: String, isCorrect: Bool) {
            let score = isCorrect ? 1 : 0
            liveTranscription = transcript
            lineStates[currentLineIndex] = LineState(transcript: transcript, score: score)

            let submission = QuizSubmission(
                questionIndex: questionIndexOffset + currentLineIndex,
                selectedAnswerIndex: score,
                isCorrect: isCorrect,
                type: .pronunciation,
                spokenText: transcript
            )
            onAnswer(submission)
        }

        private func finishQuizIfNeeded() {
            guard allLinesAnswered else { return }
            let submissions: [QuizSubmission] = items.enumerated().compactMap { index, _ in
                guard let lineState = lineStates[index], let score = lineState.score else { return nil }
                return QuizSubmission(
                    questionIndex: questionIndexOffset + index,
                    selectedAnswerIndex: score,
                    isCorrect: score == 1,
                    type: .pronunciation,
                    spokenText: lineState.transcript
                )
            }
            onCompletion(submissions)
        }

        private func evaluate(spokenText: String) -> Bool {
            guard let expected = currentItem?.lyricLine else { return false }
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
}
