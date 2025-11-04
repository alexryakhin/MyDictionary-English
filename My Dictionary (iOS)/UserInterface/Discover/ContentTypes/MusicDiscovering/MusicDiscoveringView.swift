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
            .padding(.vertical)
        }
        .groupedBackground()
        .navigation(
            title: Loc.Navigation.Tabbar.discover,
            trailingContent: {
                contentPicker
            },
            bottomContent: {
                tabSelector
            }
        )
        .overlay {
            emptyOverlayView
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
        if viewModel.suggestedSongs.isNotEmpty {
            CustomSectionView(header: "Suggested Songs") {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(viewModel.suggestedSongs) { song in
                            SongSuggestionCard(song: song) {
                                Task {
                                    await viewModel.selectSong(song)
                                }
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
                .scrollTargetBehavior(.viewAligned)
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
            Text("Connect to Apple Music or Spotify to get personalized song recommendations")
        } actions: {
            HeaderButton("Connect", size: .large, style: .borderedProminent) {
                // TODO: present auth with Spotify, I guess, since if user had Apple Music, user would not see this view
            }
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
            if viewModel.suggestedSongs.isEmpty {
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
}
