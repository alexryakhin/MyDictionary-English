//
//  SongLessonInfoDetailView.swift
//  My Dictionary (macOS)
//
//  Created by Aleksandr Riakhin on 11/12/25.
//

import SwiftUI

struct SongLessonInfoDetailView: View {
    @Environment(\.openWindow) private var openWindow
    @StateObject private var viewModel: SongLessonInfoSheetViewModel

    let song: Song

    init(song: Song) {
        self.song = song
        _viewModel = StateObject(wrappedValue: SongLessonInfoSheetViewModel(song: song))
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                artworkSection
                titleSection
                hookSection
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .groupedBackground()
        .safeAreaBarIfAvailable {
            ActionButton(
                buttonTitle,
                style: .borderedProminent
            ) {
                startLessonIfPossible()
            }
            .disabled(viewModel.hookState == .loading)
            .padding(.vertical, 12)
            .padding(.horizontal, 24)
        }
        .task {
            AnalyticsService.shared.logEvent(
                .musicDiscoveringLessonPreviewShown,
                parameters: [
                    "song_id": song.serviceId,
                    "cefr_level": song.cefrLevel?.rawValue ?? "unknown",
                    "is_favorite": viewModel.isFavorite ? 1 : 0
                ]
            )
            viewModel.handle(.loadData)
        }
    }
    
    private var artworkSection: some View {
        ZStack(alignment: .topTrailing) {
            CachedAsyncImage(url: viewModel.song.albumArtURL) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        Image(systemName: "music.note")
                            .font(.largeTitle)
                            .foregroundColor(.white)
                    )
            }
            .frame(width: 260, height: 260)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.3), radius: 12, x: 0, y: 6)
            
            Button {
                viewModel.handle(.toggleFavorite)
            } label: {
                Image(systemName: viewModel.isFavorite ? "heart.fill" : "heart")
                    .font(.title2)
                    .foregroundColor(viewModel.isFavorite ? .red : .white)
                    .padding(12)
                    .background(
                        Circle()
                            .fill(.ultraThinMaterial)
                    )
                    .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
            }
            .buttonStyle(.plain)
            .padding(12)
        }
    }
    
    private var titleSection: some View {
        VStack(spacing: 6) {
            Text(viewModel.song.title)
                .font(.system(size: 28, weight: .semibold))
                .multilineTextAlignment(.center)
            
            Text(viewModel.song.artist)
                .font(.title3)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    @ViewBuilder
    private var hookSection: some View {
        switch viewModel.hookState {
        case .loaded(_, let preListenHook):
            PreListenHookView(hook: preListenHook)
        case .failed(let musicError):
            if case .lyricsNotFound = musicError {
                LyricsErrorView()
            } else {
                DiscoverOverviewPlaceholderView(
                    icon: "exclamationmark.triangle",
                    title: Loc.MusicDiscovering.Sheet.LyricsUnavailable.title,
                    subtitle: Loc.MusicDiscovering.Sheet.LyricsUnavailable.body
                )
            }
        case .loading:
            HookLoadingSkeleton()
        }
    }
    
    private var buttonTitle: String {
        switch viewModel.hookState {
        case .loaded:
            return Loc.MusicDiscovering.Sheet.Cta.startLesson
        case .failed:
            return Loc.Actions.retry
        case .loading:
            return Loc.Actions.loading
        }
    }

    private func startLessonIfPossible() {
        switch viewModel.hookState {
        case .loaded(let lyrics, _):
            guard viewModel.song.cefrLevel != nil else { return }
            let config = MusicPlayerConfig(
                song: viewModel.song,
                lyrics: lyrics
            )
            openWindow(id: WindowID.musicLesson, value: config)
        case .failed:
            viewModel.handle(.loadData)
        case .loading:
            break
        }
    }
}
