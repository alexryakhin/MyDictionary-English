//
//  MusicDiscoveringView.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin
//

import SwiftUI

struct MusicDiscoveringView<ContentPicker: View>: View {
    @ObservedObject private var discoverViewModel: DiscoverViewModel
    private let contentPicker: ContentPicker

    @AppStorage(UDKeys.appleMusicAuthorized) private var isAppleMusicAuthorized: Bool = false
    @StateObject private var viewModel = MusicDiscoveringViewModel()
    @State private var selectedSong: Song?

    init(discoverViewModel: DiscoverViewModel, contentPicker: ContentPicker) {
        self.discoverViewModel = discoverViewModel
        self.contentPicker = contentPicker
    }
    
    private var isSearchActive: Bool {
        !viewModel.searchText.isEmpty
    }

    var body: some View {
        ScrollView {
            if isAppleMusicAuthorized {
                LazyVStack(spacing: 20) {
                    if isSearchActive && !viewModel.searchText.isEmpty {
                        // Show search results when searching
                        searchResultsSection
                    } else {
                        // Show all sections when not searching
                        notFinishedSection
                        recommendedForYouSection
                        favoriteSongsSection
                        historySection
                    }
                }
                .padding(vertical: 12, horizontal: 16)
            } else {
                MusicAuthenticationView()
                    .onDisappear {
                        viewModel.handle(.loadData)
                    }
            }
        }
        .groupedBackground()
        .navigation(
            title: Loc.Navigation.Tabbar.discover,
            trailingContent: {
                contentPicker
            },
            bottomContent: {
                if isAppleMusicAuthorized {
                    InputView.searchView(
                        Loc.Words.search,
                        searchText: $viewModel.searchText
                    )
                }
            }
        )
        .overlay {
            if isAppleMusicAuthorized {
                emptyOverlayView
            }
        }
        .onChange(of: viewModel.searchText) { _, newValue in
            if !newValue.isEmpty {
                viewModel.handle(.filterSectionsBySearch(query: newValue))
            } else {
                viewModel.handle(.clearSearch)
            }
        }
        .sheet(item: $selectedSong) { song in
            SongLessonInfoSheetView(song: song, onStartLesson: { songToStart, lyrics in
                selectedSong = nil // Dismiss the sheet
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    let config = MusicPlayerConfig(song: songToStart, lyrics: lyrics)
                    NavigationManager.shared.navigate(to: .musicPlayer(config))
                }
            })
        }
        .task(id: isAppleMusicAuthorized) {
            // Only load data when authorization status changes or first time
            if isAppleMusicAuthorized {
                viewModel.handle(.loadData)
            }
        }
    }

    // MARK: - Sections
    
    @ViewBuilder
    private var notFinishedSection: some View {
        if !viewModel.incompleteSessions.isEmpty {
            CustomSectionView(header: "Not Finished") {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(viewModel.incompleteSessions) { session in
                            if let song = session.song {
                                SongSuggestionCard(
                                    song: song,
                                    songTag: viewModel.songTags[song.id],
                                    generationCount: viewModel.songGenerationCounts[song.id]
                                ) {
                                    selectedSong = song
                                }
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
                .scrollTargetBehavior(.viewAligned)
                .scrollClipDisabled()
            }
        }
    }
    
    @ViewBuilder
    private var recommendedForYouSection: some View {
        if viewModel.recommendationSongs.isNotEmpty {
            CustomSectionView(header: "Recommended For You") {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(viewModel.recommendationSongs) { song in
                            SongSuggestionCard(
                                song: song,
                                songTag: viewModel.songTags[song.id],
                                generationCount: viewModel.songGenerationCounts[song.id]
                            ) {
                                selectedSong = song
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
                .scrollTargetBehavior(.viewAligned)
                .scrollClipDisabled()
            }
        }
    }
    
    @ViewBuilder
    private var favoriteSongsSection: some View {
        if !viewModel.favoriteSongs.isEmpty {
            CustomSectionView(header: "Favorite Songs") {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(viewModel.favoriteSongs) { session in
                            if let song = session.song {
                                SongSuggestionCard(
                                    song: song,
                                    songTag: viewModel.songTags[song.id],
                                    generationCount: viewModel.songGenerationCounts[song.id]
                                ) {
                                    selectedSong = song
                                }
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
                .scrollTargetBehavior(.viewAligned)
                .scrollClipDisabled()
            }
        }
    }
    
    @ViewBuilder
    private var searchResultsSection: some View {
        if viewModel.isSearching {
            CustomSectionView(header: "Searching...") {
                ProgressView()
                    .padding()
            }
        } else if !viewModel.searchResults.isEmpty {
            CustomSectionView(header: "Search Results") {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.searchResults) { song in
                        SongSuggestionCard(
                            song: song,
                            songTag: viewModel.songTags[song.id],
                            generationCount: viewModel.songGenerationCounts[song.id]
                        ) {
                            selectedSong = song
                        }
                    }
                }
                .padding(.vertical, 8)
            }
        }
    }

    // MARK: - History Section

    @ViewBuilder
    private var historySection: some View {
        if !viewModel.completedSessions.isEmpty {
            CustomSectionView(header: "History") {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.completedSessions) { session in
                        if let song = session.song {
                            SongSuggestionCard(
                                song: song,
                                songTag: viewModel.songTags[song.id],
                                generationCount: viewModel.songGenerationCounts[song.id]
                            ) {
                                selectedSong = song
                            }
                        }
                    }
                }
                .padding(.vertical, 8)
            }
        }
    }

    // MARK: - Empty overlay
    
    @ViewBuilder
    private var emptyOverlayView: some View {
        if isSearchActive && !viewModel.searchText.isEmpty {
            if !viewModel.isSearching && viewModel.searchResults.isEmpty {
                emptySearchResultsView
            }
        } else {
            if case .loadingSuggestions = viewModel.loadingStatus {
                loadingSuggestionsView
            } else if viewModel.incompleteSessions.isEmpty &&
                      viewModel.recommendationSongs.isEmpty &&
                      viewModel.favoriteSongs.isEmpty &&
                      viewModel.completedSessions.isEmpty {
                emptyAllSectionsView
            }
        }
    }
    
    private var emptySearchResultsView: some View {
        ContentUnavailableView(
            "No results found",
            systemImage: "magnifyingglass",
            description: Text("Try searching for a different song")
        )
    }
    
    private var emptyAllSectionsView: some View {
        ContentUnavailableView(
            "No songs available",
            systemImage: "music.note.list",
            description: Text("Start exploring songs to build your collection")
        )
    }
    
    private var loadingSuggestionsView: some View {
        MusicDiscoveringSkeletonView()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Skeleton Loading Views

struct MusicDiscoveringSkeletonView: View {
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                // Recommended For You Section Skeleton
                recommendedSectionSkeleton
                
                // Favorite Songs Section Skeleton
                favoriteSectionSkeleton
                
                // History Section Skeleton
                historySectionSkeleton
            }
            .padding(vertical: 12, horizontal: 16)
        }
    }
    
    private var recommendedSectionSkeleton: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section header shimmer
            ShimmerView(width: 180, height: 24)
                .clipShape(RoundedRectangle(cornerRadius: 6))
            
            // Horizontal scrolling cards
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(0..<4, id: \.self) { _ in
                        SongCardSkeleton()
                    }
                }
            }
        }
    }
    
    private var favoriteSectionSkeleton: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section header shimmer
            ShimmerView(width: 140, height: 24)
                .clipShape(RoundedRectangle(cornerRadius: 6))
            
            // Horizontal scrolling cards
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(0..<3, id: \.self) { _ in
                        SongCardSkeleton()
                    }
                }
            }
        }
    }
    
    private var historySectionSkeleton: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section header shimmer
            ShimmerView(width: 100, height: 24)
                .clipShape(RoundedRectangle(cornerRadius: 6))
            
            // Vertical list of cards
            VStack(spacing: 12) {
                ForEach(0..<3, id: \.self) { _ in
                    HStack(spacing: 12) {
                        SongCardSkeleton()
                        Spacer()
                    }
                }
            }
        }
    }
}

struct SongCardSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Album artwork shimmer
            ShimmerView(width: 140, height: 140)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            
            VStack(alignment: .leading, spacing: 6) {
                // CEFR badge shimmer
                ShimmerView(width: 35, height: 18)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                
                // Title shimmer (2 lines)
                ShimmerView(width: 130, height: 14)
                ShimmerView(width: 100, height: 14)
                
                // Artist shimmer
                ShimmerView(width: 110, height: 12)
                
                // Theme tags shimmer
                HStack(spacing: 4) {
                    ShimmerView(width: 50, height: 16)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    ShimmerView(width: 60, height: 16)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }
        }
        .frame(width: 140)
    }
}

// MARK: - Previews

#Preview("Skeleton Loading") {
    MusicDiscoveringSkeletonView()
        .groupedBackground()
}

#Preview("Single Card Skeleton") {
    SongCardSkeleton()
        .padding()
        .groupedBackground()
}
