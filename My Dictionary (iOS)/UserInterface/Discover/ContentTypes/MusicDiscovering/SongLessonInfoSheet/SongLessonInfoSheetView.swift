//
//  SongLessonInfoSheetView.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin
//

import SwiftUI

struct SongLessonInfoSheetView: View {
    let onStartLesson: (Song, SongLyrics) -> Void
    @StateObject private var viewModel: SongLessonInfoSheetViewModel
    @Environment(\.dismiss) private var dismiss
    
    init(song: Song, onStartLesson: @escaping (Song, SongLyrics) -> Void) {
        self.onStartLesson = onStartLesson
        _viewModel = StateObject(wrappedValue: SongLessonInfoSheetViewModel(song: song))
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Artwork with Favorite Button
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
                    .frame(width: 240, height: 240)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: .black.opacity(0.3), radius: 12, x: 0, y: 6)
                    
                    // Favorite Button
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
                    .padding(12)
                }
                
                // Title and Artist
                VStack(spacing: 6) {
                    Text(viewModel.song.title)
                        .font(.title)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                    Text(viewModel.song.artist)
                        .font(.title3)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                // AI Hook - Show full pre-listen hook, loading skeleton, or error
                switch viewModel.hookState {
                case .loaded(_, let preListenHook):
                    PreListenHookView(hook: preListenHook)
                case .failed(let musicError):
                    LyricsErrorView()
                case .loading:
                    HookLoadingSkeleton()
                }
            }
            .padding()
        }
        .safeAreaBarIfAvailable {
            ActionButton(
                buttonTitle,
                style: .borderedProminent
            ) {
                switch viewModel.hookState {
                case .loaded(let songLyrics, _):
                    guard viewModel.song.cefrLevel != nil else { return }
                    AnalyticsService.shared.logEvent(
                        .musicDiscoveringLessonStart,
                        parameters: [
                            "song_id": viewModel.song.serviceId,
                            "cefr_level": viewModel.song.cefrLevel?.rawValue ?? "unknown",
                            "is_favorite": viewModel.isFavorite ? 1 : 0
                        ]
                    )
                    onStartLesson(viewModel.song, songLyrics)
                case .failed(let string):
                    viewModel.handle(.loadData)
                case .loading:
                    break
                }
            }
            .disabled(viewModel.hookState == .loading)
            .padding(vertical: 12, horizontal: 16)
        }
        .task {
            AnalyticsService.shared.logEvent(
                .musicDiscoveringLessonPreviewShown,
                parameters: [
                    "song_id": viewModel.song.serviceId,
                    "cefr_level": viewModel.song.cefrLevel?.rawValue ?? "unknown",
                    "is_favorite": viewModel.isFavorite ? 1 : 0
                ]
            )
            viewModel.handle(.loadData)
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
}

// MARK: - PremiumRequiredView

struct PremiumRequiredView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "star.circle.fill")
                .font(.system(size: 50))
                .foregroundColor(.yellow)
            
            Text(Loc.MusicDiscovering.Sheet.Premium.title)
                .font(.title3)
                .fontWeight(.semibold)
            
            Text(Loc.MusicDiscovering.Sheet.Premium.body)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            ActionButton(
                Loc.MusicDiscovering.Sheet.Premium.ctaUpgrade,
                style: .borderedProminent
            ) {
                PaywallService.shared.presentPaywall(for: .aiLessons)
            }
            .padding(.top, 8)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.yellow.opacity(0.1))
        )
    }
}

// MARK: - LyricsErrorView


