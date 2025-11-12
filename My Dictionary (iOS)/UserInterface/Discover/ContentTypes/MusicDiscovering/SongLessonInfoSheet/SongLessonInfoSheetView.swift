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
                    if case .lyricsNotFound = musicError {
                        LyricsErrorView()
                    }
                case .loading:
                    HookLoadingSkeleton()
                }
            }
            .padding()
        }
        .safeAreaBarIfAvailable {
            ActionButton(
                Loc.MusicDiscovering.Sheet.Cta.startLesson,
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

struct LyricsErrorView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundColor(.orange)
            
            Text(Loc.MusicDiscovering.Sheet.LyricsUnavailable.title)
                .font(.title3)
                .fontWeight(.semibold)
            
            Text(Loc.MusicDiscovering.Sheet.LyricsUnavailable.body)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.orange.opacity(0.1))
        )
    }
}

// MARK: - HookLoadingSkeleton

struct HookLoadingSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Main Hook Text Shimmer (multiline)
            VStack(alignment: .leading, spacing: 8) {
                ShimmerView(height: 16)
                ShimmerView(height: 16)
                ShimmerView(width: 250, height: 16)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .clippedWithPaddingAndBackground(Color.accent.opacity(0.1))

            // Key Phrases Section
            VStack(alignment: .leading, spacing: 12) {
                ShimmerView(width: 100, height: 14)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                
                // Phrase 1
                HStack(alignment: .top, spacing: 8) {
                    ShimmerView(width: 40, height: 20)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    VStack(alignment: .leading, spacing: 4) {
                        ShimmerView(width: 200, height: 14)
                        ShimmerView(width: 150, height: 12)
                        ShimmerView(width: 180, height: 10)
                    }
                }
                
                // Phrase 2
                HStack(alignment: .top, spacing: 8) {
                    ShimmerView(width: 40, height: 20)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    VStack(alignment: .leading, spacing: 4) {
                        ShimmerView(width: 180, height: 14)
                        ShimmerView(width: 160, height: 12)
                        ShimmerView(width: 190, height: 10)
                    }
                }
                
                // Phrase 3
                HStack(alignment: .top, spacing: 8) {
                    ShimmerView(width: 40, height: 20)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    VStack(alignment: .leading, spacing: 4) {
                        ShimmerView(width: 190, height: 14)
                        ShimmerView(width: 140, height: 12)
                        ShimmerView(width: 170, height: 10)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .clippedWithPaddingAndBackground(Color.accent.opacity(0.1))

            // Grammar Highlight Shimmer
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    ShimmerView(width: 16, height: 16)
                    ShimmerView(width: 80, height: 14)
                }
                ShimmerView(height: 12)
                ShimmerView(width: 220, height: 12)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .clippedWithPaddingAndBackground(Color.accent.opacity(0.1))

            // Cultural Note Shimmer
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    ShimmerView(width: 16, height: 16)
                    ShimmerView(width: 100, height: 14)
                }
                ShimmerView(height: 12)
                ShimmerView(width: 240, height: 12)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .clippedWithPaddingAndBackground(Color.accent.opacity(0.1))
        }
    }
}

// MARK: - PreListenHookView

struct PreListenHookView: View {
    let hook: PreListenHook
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Main Hook Text
            Text(hook.hook)
                .font(.body)
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .clippedWithPaddingAndBackground(Color.accent.opacity(0.1))

            // Target Phrases
            if !hook.targetPhrases.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text(Loc.MusicDiscovering.Lesson.Phrases.header)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    
                    ForEach(hook.targetPhrases.indices, id: \.self) { index in
                        let phrase = hook.targetPhrases[index]
                        HStack(alignment: .top, spacing: 8) {
                            TagView(
                                text: phrase.cefr.rawValue,
                                color: phrase.cefr.color,
                                size: .mini
                            )
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(phrase.phrase)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                if let meaning = phrase.meaning {
                                    Text(meaning)
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                        .italic()
                                }
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .clippedWithPaddingAndBackground(Color.accent.opacity(0.1))
            }
            
            // Grammar Highlight
            if let grammar = hook.grammarHighlight, !grammar.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Label(Loc.MusicDiscovering.Sheet.Hook.grammar, systemImage: "book.fill")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    Text(grammar)
                        .font(.caption)
                        .foregroundColor(.primary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .clippedWithPaddingAndBackground(Color.accent.opacity(0.1))
            }
            
            // Cultural Note
            if let culture = hook.culturalNote, !culture.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Label(Loc.MusicDiscovering.Sheet.Hook.culturalNote, systemImage: "globe")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    Text(culture)
                        .font(.caption)
                        .foregroundColor(.primary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .clippedWithPaddingAndBackground(Color.accent.opacity(0.1))
            }
        }
    }
}
