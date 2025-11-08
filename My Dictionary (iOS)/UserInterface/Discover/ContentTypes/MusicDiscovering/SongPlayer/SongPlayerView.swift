//
//  SongPlayerView.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin
//

import SwiftUI

struct MusicPlayerConfig: Hashable {
    let song: Song
    let lyrics: SongLyrics?
    
    static func == (lhs: MusicPlayerConfig, rhs: MusicPlayerConfig) -> Bool {
        return lhs.song.id == rhs.song.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(song.id)
    }
}

struct SongPlayerView: View {
    let song: Song
    @StateObject private var viewModel: SongPlayerViewModel
    @Environment(\.dismiss) private var dismiss
    
    init(song: Song, lyrics: SongLyrics? = nil) {
        self.song = song
        _viewModel = StateObject(wrappedValue: SongPlayerViewModel(song: song, lyrics: lyrics))
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Main scrollable lyrics content
            if let lyrics = viewModel.lyrics {
                InteractiveLyricsView(
                    lyrics: lyrics,
                    currentTime: viewModel.currentTime,
                    onLineSelected: { timestamp in
                        viewModel.handle(.seek(to: timestamp))
                    }
                )
            } else {
                lyricsUnavailableView
            }
            
            // Bottom pinned controls
            bottomControlsView
                .background(.ultraThinMaterial)
                .ignoresSafeArea(edges: .bottom)
        }
        .groupedBackground()
        .toolbar {
            ToolbarItem(placement: .principal) {
                navigationTitleView
            }
        }
        .task {
            viewModel.handle(.loadData)
        }
    }
    
    // MARK: - Navigation Title View
    
    private var navigationTitleView: some View {
        HStack(spacing: 12) {
            // Small album artwork
            AsyncImage(url: song.albumArtURL) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            colors: [.blue.opacity(0.4), .purple.opacity(0.4)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        Image(systemName: "music.note")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                    )
            }
            .frame(width: 60, height: 60)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            // Song info
            VStack(alignment: .leading, spacing: 2) {
                Text(song.title)
                    .font(.headline)
                    .lineLimit(1)
                
                Text(song.artist)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - Bottom Controls View
    
    private var bottomControlsView: some View {
        VStack(spacing: 16) {
            // Progress Slider
            VStack(spacing: 8) {
                Slider(
                    value: Binding(
                        get: { viewModel.currentTime },
                        set: { viewModel.handle(.seek(to: $0)) }
                    ),
                    in: 0...max(viewModel.duration, 1)
                )
                .tint(.accentColor)
                
                HStack {
                    Text(formatTime(viewModel.currentTime))
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
            
            // Play/Pause Button
            Button(action: {
                viewModel.handle(.playPause)
            }) {
                Image(systemName: viewModel.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 56))
                    .foregroundColor(.primary)
            }
            
            // Lesson Button or Progress
            if viewModel.isGeneratingLesson {
                lessonGenerationProgress
            } else if viewModel.lessonReady,
                      let lesson = viewModel.adaptedLesson,
                      let session = viewModel.session {
                continueToLessonButton(lesson: lesson, session: session)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }
    
    private var lyricsUnavailableView: some View {
        VStack(spacing: 16) {
            Image(systemName: "music.note.text")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("Lyrics not available")
                .font(.title3)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
    
    private func continueToLessonButton(lesson: AdaptedLesson, session: MusicDiscoveringSession) -> some View {
        ActionButton(
            "Continue to Lesson",
            style: .borderedProminent
        ) {
            let config = SongLessonConfig(song: song, lesson: lesson, session: session)
            NavigationManager.shared.navigate(to: .songLesson(config))
        }
    }
    
    // MARK: - Helper Methods
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}


