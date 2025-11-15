//
//  SpeechQuizView.swift
//  My Dictionary (macOS)
//
//  Created by GPT-5 Codex
//

import SwiftUI
import AppKit

extension SongLesson {
    struct SpeechQuizView: View {
        private let config: SpeechQuizConfig

        @StateObject private var viewModel: SpeechQuizViewModel
        @State private var showPermissionAlert = false

        init(config: SpeechQuizConfig) {
            self.config = config
            _viewModel = StateObject(
                wrappedValue: SpeechQuizViewModel(
                    items: config.items,
                    initialAnswers: config.initialAnswers,
                    questionIndexOffset: config.questionIndexOffset,
                    localeIdentifier: config.localeIdentifier,
                    initialTranscripts: config.initialTranscripts,
                    onAnswer: config.onAnswer,
                    onCompletion: config.onCompletion
                )
            )
        }

        var body: some View {
            VStack(alignment: .leading, spacing: 20) {
                ProgressView(
                    value: Double(viewModel.currentLineIndex + 1),
                    total: Double(max(viewModel.items.count, 1))
                )
                .progressViewStyle(.linear)

                Text(
                    Loc.MusicDiscovering.Quiz.Common.questionProgress(
                        viewModel.currentLineIndex + 1,
                        viewModel.items.count
                    )
                )
                .font(.caption)
                .foregroundColor(.secondary)

                if let item = viewModel.currentItem {
                    quizCard(for: item)
                }

                navigationBar
            }
            .alert(
                Loc.MusicDiscovering.Quiz.Pronunciation.permissionsTitle,
                isPresented: $showPermissionAlert
            ) {
                Button(Loc.Actions.settings) {
                    if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone") {
                        NSWorkspace.shared.open(url)
                    }
                }
                Button(Loc.Actions.cancel, role: .cancel) {}
            } message: {
                Text(Loc.MusicDiscovering.Quiz.Pronunciation.permissionsMessage)
            }
            .onReceive(viewModel.$permissionsStatus) { status in
                if case .denied = status {
                    showPermissionAlert = true
                }
            }
        }

        @ViewBuilder
        private func quizCard(for item: SpeechQuizItem) -> some View {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(Loc.MusicDiscovering.Quiz.Pronunciation.prompt)
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    lyricLineView(item: item)
                }

                if viewModel.isRecording {
                    listenIndicator
                }

                if viewModel.currentState.transcript.isNotEmpty {
                    spokenResultView(transcript: viewModel.currentState.transcript)
                } else if viewModel.liveTranscription.isNotEmpty {
                    spokenResultView(transcript: viewModel.liveTranscription, isPreview: true)
                }

                if let explanation = explanationView(for: item) {
                    explanation
                }

                let isCorrectScore = viewModel.currentState.score == 1
                if !isCorrectScore {
                    recordButton
                }
            }
            .padding(20)
            .background(.tertiarySystemGroupedBackground)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        }

        private func lyricLineView(item: SpeechQuizItem) -> some View {
            let score = viewModel.currentState.score
            let backgroundColor: Color
            let foregroundColor: Color

            switch score {
            case 1:
                backgroundColor = Color.green.opacity(0.2)
                foregroundColor = .green
            case 0:
                backgroundColor = Color.red.opacity(0.2)
                foregroundColor = .red
            default:
                backgroundColor = Color(NSColor.windowBackgroundColor)
                foregroundColor = .primary
            }

            return Text(item.lyricLine)
                .font(.title3)
                .fontWeight(.semibold)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(backgroundColor)
                .foregroundColor(foregroundColor)
                .cornerRadius(12)
                .onTapGesture {
                    Task {
                        guard TTSPlayer.shared.isPlaying == false && viewModel.isRecording == false else { return }
                        try await TTSPlayer.shared.play(item.lyricLine)
                    }
                }
        }

        private var navigationBar: some View {
            HStack {
                ActionButton(
                    Loc.MusicDiscovering.Quiz.Navigation.previous,
                    systemImage: "chevron.left"
                ) {
                    viewModel.goToPreviousLine()
                }
                .disabled(viewModel.currentLineIndex == 0 || viewModel.isRecording || viewModel.isProcessingResult)

                Spacer()

                let isLastQuestion = viewModel.currentLineIndex == viewModel.items.count - 1
                ActionButton(
                    isLastQuestion
                    ? Loc.MusicDiscovering.Quiz.Pronunciation.finish
                    : Loc.MusicDiscovering.Quiz.Navigation.next,
                    systemImage: isLastQuestion ? "checkmark" : "chevron.right"
                ) {
                    viewModel.goToNextLine()
                }
                .disabled(!viewModel.canGoToNextLine || isLastQuestion)
            }
        }

        private var recordButton: some View {
            Button {
                Task {
                    switch viewModel.permissionsStatus {
                    case .unknown:
                        await viewModel.requestPermissions()
                        guard viewModel.permissionsStatus == .granted else {
                            await MainActor.run {
                                showPermissionAlert = true
                            }
                            return
                        }
                        await viewModel.toggleRecording()
                    case .denied:
                        await MainActor.run {
                            showPermissionAlert = true
                        }
                        return
                    case .granted:
                        await viewModel.toggleRecording()
                    }
                }
            } label: {
                Label(
                    viewModel.isRecording
                        ? Loc.MusicDiscovering.Quiz.Pronunciation.stopButton
                        : Loc.MusicDiscovering.Quiz.Pronunciation.recordButton,
                    systemImage: viewModel.isRecording ? "stop.fill" : "mic.fill"
                )
                .font(.title3.bold())
                .frame(minWidth: 260)
                .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(viewModel.isRecording ? .red : .accentColor)
            .disabled(viewModel.permissionsStatus == .denied || viewModel.isProcessingResult)
        }

        private var listenIndicator: some View {
            HStack(spacing: 8) {
                ProgressView()
                    .progressViewStyle(.circular)
                Text(Loc.MusicDiscovering.Quiz.Pronunciation.listening)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }

        private func spokenResultView(transcript: String, isPreview: Bool = false) -> some View {
            VStack(alignment: .leading, spacing: 6) {
                Text(
                    isPreview
                    ? Loc.MusicDiscovering.Quiz.Pronunciation.previewText
                    : Loc.MusicDiscovering.Quiz.Pronunciation.resultText
                )
                .font(.caption)
                .foregroundColor(.secondary)

                Text(transcript)
                    .font(.body)
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }

        private func explanationView(for item: SpeechQuizItem) -> AnyView? {
            guard let score = viewModel.currentState.score else { return nil }
            let isCorrect = score == 1

            let explanationStack = VStack(alignment: .leading, spacing: 6) {
                Text(
                    isCorrect
                    ? Loc.MusicDiscovering.Quiz.Pronunciation.correctTitle
                    : Loc.MusicDiscovering.Quiz.Pronunciation.incorrectTitle
                )
                .font(.footnote)
                .foregroundColor(isCorrect ? .green : .red)

                Text(item.explanation)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            return AnyView(explanationStack)
        }
    }
}

