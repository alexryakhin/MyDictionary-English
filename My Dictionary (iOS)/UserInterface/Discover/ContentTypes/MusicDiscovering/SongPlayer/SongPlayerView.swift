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
    @State private var isTipsSheetPresented: Bool = false

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
                HeaderButton(
                    icon: "info"
                ) {
                    isTipsSheetPresented = true
                }
            }
        )
        .safeAreaBarIfAvailable {
            VStack(spacing: 8) {
                VStack(spacing: 2) {
                    SongProgressBar(
                        isDragging: $viewModel.isSeeking,
                        progress: $viewModel.currentTime,
                        duration: viewModel.duration
                    )

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
                ActionButton(
                    viewModel.isPlaying ? Loc.Actions.pause : Loc.Actions.play,
                    systemImage: viewModel.isPlaying ? "pause" : "play"
                ) {
                    viewModel.handle(.playPause)
                }
                .disabled(!viewModel.sessionIsActive)

                ActionButton(
                    lessonButtonTitle,
                    style: .borderedProminent
                ) {
                    lessonButtonAction()
                }
                .disabled(isLessonButtonDisabled)
            }
            .padding(vertical: 12, horizontal: 16)
        }
        .sheet(isPresented: $isTipsSheetPresented) {
            tipsSheetContent
        }
        .onAppear {
            if !UDService.songPlayerTipsShown {
                isTipsSheetPresented = true
            }
        }
        .onChange(of: isTipsSheetPresented) { _, newValue in
            if newValue {
                UDService.songPlayerTipsShown = true
            }
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
            
            Text(Loc.MusicDiscovering.Player.Lesson.generating)
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
        viewModel.currentTime
    }
    
    private var lessonButtonTitle: String {
        switch viewModel.lessonState {
        case .loading:
            Loc.MusicDiscovering.Player.Lesson.loading
        case .ready:
            Loc.MusicDiscovering.Player.Lesson.ready
        case .failed:
            Loc.MusicDiscovering.Player.Lesson.failed
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
            AnalyticsService.shared.logEvent(
                .musicDiscoveringLessonOpened,
                parameters: [
                    "song_id": song.serviceId,
                    "language_code": lesson.language.rawValue,
                    "session_id": session.id.uuidString
                ]
            )
            let config = SongLessonConfig(song: song, lesson: lesson, session: session)
            NavigationManager.shared.navigate(to: .songLesson(config))
        case .failed:
            viewModel.handle(.generateLesson)
        }
    }
    
    private var tipsSheetContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(Loc.MusicDiscovering.Player.Tips.header)
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(.primary)

                    Text(Loc.MusicDiscovering.Player.Tips.intro)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                FormWithDivider(dividerLeadingPadding: .zero, dividerTrailingPadding: .zero) {
                    tipRow(
                        icon: "list.bullet.rectangle",
                        title: Loc.MusicDiscovering.Player.Tips.exploreTitle,
                        message: Loc.MusicDiscovering.Player.Tips.exploreMessage
                    )

                    tipRow(
                        icon: "book.closed",
                        title: Loc.MusicDiscovering.Player.Tips.carryTitle,
                        message: Loc.MusicDiscovering.Player.Tips.carryMessage
                    )

                    tipRow(
                        icon: "sparkles",
                        title: Loc.MusicDiscovering.Player.Tips.pathTitle,
                        message: Loc.MusicDiscovering.Player.Tips.pathMessage
                    )
                }
            }
            .padding(vertical: 12, horizontal: 16)
        }
        .navigation(
            title: Loc.MusicDiscovering.Player.Tips.title,
            mode: .regular,
            trailingContent: {
                HeaderButton(Loc.Actions.done) {
                    isTipsSheetPresented = false
                }
            }
        )
        .presentationDetents([.medium])
    }
    
    private func tipRow(icon: String, title: String, message: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.title3.weight(.medium))
                    .frame(width: 28, height: 28)
                    .foregroundStyle(.accent)
                
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)
            }
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 12)
    }
}
