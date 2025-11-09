//
//  SongPlayerView.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin
//

import SwiftUI

struct MusicPlayerConfig: Hashable {
    let song: Song
    let lyrics: SongLyrics
    
    static func == (lhs: MusicPlayerConfig, rhs: MusicPlayerConfig) -> Bool {
        return lhs.song.id == rhs.song.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(song.id)
    }
}

struct SongPlayerView: View {
    let config: MusicPlayerConfig
    @StateObject private var viewModel: SongPlayerViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var isSeeking = false
    @State private var pendingSeekTime: TimeInterval?
    
    private var song: Song { config.song }
    
    init(config: MusicPlayerConfig) {
        self.config = config
        _viewModel = StateObject(wrappedValue: SongPlayerViewModel(song: config.song, lyrics: config.lyrics))
    }
    
    var body: some View {
        InteractiveLyricsView(
            viewModel: viewModel
        )
        .groupedBackground()
        .navigation(
            title: song.title,
            mode: .regular,
            showsBackButton: true,
            trailingContent: {
                HeaderButton(icon: viewModel.isPlaying ? "pause" : "play") {
                    viewModel.handle(.playPause)
                }
            },
            bottomContent: {
                VStack(spacing: 2) {
                    Slider(
                        value: Binding(
                            get: { pendingSeekTime ?? viewModel.currentTime },
                            set: { newValue in
                                if isSeeking {
                                    pendingSeekTime = newValue
                                } else {
                                    viewModel.handle(.seek(to: newValue))
                                }
                            }
                        ),
                        in: 0...max(viewModel.duration, 1),
                        onEditingChanged: { editing in
                            if editing {
                                isSeeking = true
                                pendingSeekTime = viewModel.currentTime
                            } else {
                                isSeeking = false
                                if let pendingSeekTime {
                                    viewModel.handle(.seek(to: pendingSeekTime))
                                }
                                pendingSeekTime = nil
                            }
                        }
                    )
                    .tint(.accentColor)

                    HStack {
                        Text(formatTime(displayedCurrentTime))
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .monospacedDigit()

                        Spacer()

                        Text(formatTime(viewModel.duration))
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .monospacedDigit()
                    }
                }
            }
        )
        .safeAreaBarIfAvailable {
            ActionButton(
                lessonButtonTitle,
                style: .borderedProminent
            ) {
                lessonButtonAction()
            }
            .disabled(isLessonButtonDisabled)
            .padding(vertical: 12, horizontal: 16)
        }
        .onDisappear {
            if viewModel.isPlaying {
                viewModel.handle(.playPause)
            }
        }
    }
    
    // MARK: - Lesson Generation Progress
    
    private var lessonGenerationProgress: some View {
        HStack(spacing: 12) {
            ProgressView()
            
            Text("Generating lesson...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }
    
    // MARK: - Helper Methods
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    private var displayedCurrentTime: TimeInterval {
        pendingSeekTime ?? viewModel.currentTime
    }
    
    private var lessonButtonTitle: String {
        switch viewModel.lessonState {
        case .loading:
            "Lesson is loading..."
        case .ready:
            "Continue to Lesson"
        case .failed:
            "Error loading lesson, retry?"
        }
    }
    
    private var isLessonButtonDisabled: Bool {
        switch viewModel.lessonState {
        case .ready: false
        default: true
        }
    }
    
    private func lessonButtonAction() {
        switch viewModel.lessonState {
        case .loading:
            break
        case .ready(let lesson, let session):
            let config = SongLessonConfig(song: song, lesson: lesson, session: session)
            NavigationManager.shared.navigate(to: .songLesson(config))
        case .failed:
            viewModel.handle(.generateLesson)
        }
    }
}
