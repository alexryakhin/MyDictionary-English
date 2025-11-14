import SwiftUI
import UIKit

struct PronunciationQuizRecorderView: View {
    private let config: PronunciationQuizConfig

    @StateObject private var viewModel: PronunciationQuizRecorderViewModel
    @State private var showPermissionAlert = false

    init(config: PronunciationQuizConfig) {
        self.config = config
        _viewModel = StateObject(wrappedValue: PronunciationQuizRecorderViewModel(config: config))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
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
            .foregroundStyle(.secondary)

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
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
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
    private func quizCard(for item: PronunciationQuizConfig.Item) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text(Loc.MusicDiscovering.Quiz.Pronunciation.prompt)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                sentenceView(text: item.text)
            }

            if viewModel.isRecording {
                listenIndicator
            }

            if viewModel.currentState.transcript.isNotEmpty {
                transcriptView(
                    label: Loc.MusicDiscovering.Quiz.Pronunciation.resultText,
                    text: viewModel.currentState.transcript
                )
            } else if viewModel.liveTranscription.isNotEmpty {
                transcriptView(
                    label: Loc.MusicDiscovering.Quiz.Pronunciation.previewText,
                    text: viewModel.liveTranscription,
                    isPreview: true
                )
            }

            if let error = viewModel.errorMessage, error.isNotEmpty {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            if viewModel.currentState.isCorrect != true {
                recordButton
            }
        }
        .clippedWithPaddingAndBackground()
    }

    private func sentenceView(text: String) -> some View {
        let state = viewModel.currentState
        let backgroundColor: Color
        let foregroundColor: Color

        switch state.isCorrect {
        case true:
            backgroundColor = Color.green.opacity(0.15)
            foregroundColor = .green
        case false:
            backgroundColor = Color.red.opacity(0.15)
            foregroundColor = .red
        case nil:
            backgroundColor = Color.tertiarySystemGroupedBackground
            foregroundColor = .primary
        }

        return Text(text)
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
                    try await TTSPlayer.shared.play(text)
                }
            }
    }

    private func transcriptView(label: String, text: String, isPreview: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(isPreview ? .secondary : .primary)

            Text(text)
                .font(.body)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
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
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding()
            .background(viewModel.isRecording ? Color.red : Color.accentColor)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
        .disabled(viewModel.permissionsStatus == .denied || viewModel.isProcessingResult)
    }

    private var listenIndicator: some View {
        HStack(spacing: 8) {
            ProgressView()
                .progressViewStyle(.circular)
            Text(Loc.MusicDiscovering.Quiz.Pronunciation.listening)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

