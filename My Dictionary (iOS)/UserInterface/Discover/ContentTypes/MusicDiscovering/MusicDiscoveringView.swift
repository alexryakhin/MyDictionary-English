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
    @StateObject private var musicPlayer = MusicPlayerService.shared
    @State private var selectedTab: MusicTab = .suggestions

    init(discoverViewModel: DiscoverViewModel, contentPicker: ContentPicker) {
        self.discoverViewModel = discoverViewModel
        self.contentPicker = contentPicker
    }

    enum MusicTab: String, CaseIterable {
        case suggestions = "Suggestions"
        case history = "History"
        case nowPlaying = "Now Playing"
        
        var icon: String {
            switch self {
            case .suggestions:
                return "sparkles"
            case .history:
                return "clock.arrow.circlepath"
            case .nowPlaying:
                return "music.note"
            }
        }
    }
    
    var body: some View {
        ScrollView {
            if isAppleMusicAuthorized {
                LazyVStack(spacing: 20) {
                    switch selectedTab {
                    case .suggestions:
                        suggestionsSection
                    case .history:
                        historySection
                    case .nowPlaying:
                        nowPlayingSection
                    }
                }
                .padding(vertical: 12, horizontal: 16)
            } else {
                MusicAuthenticationView()
                    .onDisappear {
                        viewModel.loadData()
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
                    tabSelector
                }
            }
        )
        .overlay {
            if isAppleMusicAuthorized {
                emptyOverlayView
            }
        }
        .task {
            viewModel.loadData()
        }
    }

    // MARK: - Tab Selector
    
    private var tabSelector: some View {
        Picker("Music Tab", selection: $selectedTab) {
            ForEach(MusicTab.allCases, id: \.self) { tab in
                Label(tab.rawValue, systemImage: tab.icon)
                    .tag(tab)
            }
        }
        .pickerStyle(.segmented)
    }
    
    // MARK: - Suggestions Section

    @ViewBuilder
    private var suggestionsSection: some View {
        // Daily 5 Section
        if viewModel.suggestedSongs.isNotEmpty {
            CustomSectionView(header: "Your Daily 5") {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(Array(viewModel.suggestedSongs.prefix(5))) { song in
                            SongSuggestionCard(
                                song: song,
                                songTag: viewModel.songTags[song.id],
                                generationCount: viewModel.songGenerationCounts[song.id]
                            ) {
                                Task {
                                    await viewModel.selectSong(song)
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
        
        // Because you mastered section
        if viewModel.dictionaryWordSongs.isNotEmpty {
            CustomSectionView(header: "Because you mastered...") {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(viewModel.dictionaryWordSongs) { song in
                            SongSuggestionCard(
                                song: song,
                                songTag: viewModel.songTags[song.id],
                                generationCount: viewModel.songGenerationCounts[song.id]
                            ) {
                                Task {
                                    await viewModel.selectSong(song)
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

    // MARK: - History Section

    @ViewBuilder
    private var historySection: some View {
        if viewModel.listeningHistory.isNotEmpty {
            CustomSectionView(header: "Listening History") {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.listeningHistory) { historyEntry in
                        HistoryEntryRow(historyEntry: historyEntry) {
                            Task {
                                await viewModel.selectSong(historyEntry.song)
                            }
                        }
                    }
                }
                .padding(.vertical, 8)
            }
        }
    }

    // MARK: - Now Playing Section

    @ViewBuilder
    private var nowPlayingSection: some View {
        if let currentSong = musicPlayer.currentSong {
            MusicPlayerView(
                song: currentSong,
                lyrics: viewModel.currentLyrics,
                viewModel: viewModel
            )
        }
    }

    // MARK: - Empty overlay
    
    private var emptySuggestionsView: some View {
        ContentUnavailableView {
            Label("No suggestions available", systemImage: "music.note.list")
        } description: {
            Text("No song suggestions available at the moment")
        }
    }

    private var emptyHistoryView: some View {
        ContentUnavailableView(
            "No listening history",
            systemImage: "clock",
            description: Text("Start listening to songs to build your history")
        )
    }

    private var emptyNowPlayingSection: some View {
        ContentUnavailableView(
            "No song playing",
            systemImage: "music.note",
            description: Text("Select a song to start playing")
        )
    }

    @ViewBuilder
    private var emptyOverlayView: some View {
        switch selectedTab {
        case .suggestions:
            if case .loadingSuggestions = viewModel.loadingStatus {
                loadingSuggestionsView
            } else if viewModel.suggestedSongs.isEmpty && viewModel.dictionaryWordSongs.isEmpty {
                emptySuggestionsView
            }
        case .history:
            if viewModel.listeningHistory.isEmpty {
                emptyHistoryView
            }
        case .nowPlaying:
            if musicPlayer.currentSong == nil {
                emptyNowPlayingSection
            }
        }
    }
    
    private var loadingSuggestionsView: some View {
        VStack(spacing: 24) {
            ProgressView()
                .progressViewStyle(.circular)
                .scaleEffect(1.5)
                .tint(.accent)
            
            Text("Loading suggestions...")
                .font(.title3)
                .foregroundColor(.secondaryLabel)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
