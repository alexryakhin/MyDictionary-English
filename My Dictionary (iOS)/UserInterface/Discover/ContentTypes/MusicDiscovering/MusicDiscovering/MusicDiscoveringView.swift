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
    @AppStorage(UDKeys.musicRecommendationsSelectedLanguage) private var selectedRecommendationLanguageCode: String = ""
    @StateObject private var viewModel = MusicDiscoveringViewModel()
    @State private var selectedSong: Song?

    init(discoverViewModel: DiscoverViewModel, contentPicker: ContentPicker) {
        self.discoverViewModel = discoverViewModel
        self.contentPicker = contentPicker
    }

    private var isSearchActive: Bool {
        !viewModel.searchText.isEmpty
    }

    private var selectedRecommendationStudyLanguage: StudyLanguage? {
        guard let activeLanguage = viewModel.activeRecommendationLanguage else { return nil }
        return viewModel.studyLanguages.first(where: { $0.language == activeLanguage })
    }

    private var recommendationLanguageSubtitle: String {
        selectedRecommendationStudyLanguage?.displayName ?? viewModel.studyLanguages.first?.displayName ?? ""
    }

    private var recommendationLanguageButtonTitle: String? {
        selectedRecommendationStudyLanguage?.displayName ?? viewModel.studyLanguages.first?.displayName
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
        .onChange(of: viewModel.searchText) { _, newValue in
            if !newValue.isEmpty {
                viewModel.handle(.filterSectionsBySearch(query: newValue))
            } else {
                viewModel.handle(.clearSearch)
            }
        }
        .onChange(of: selectedRecommendationLanguageCode) { _, newCode in
            guard let language = InputLanguage(rawValue: newCode),
                  viewModel.studyLanguages.contains(where: { $0.language == language }) else { return }
            if viewModel.activeRecommendationLanguage != language {
                viewModel.handle(.selectRecommendationLanguage(language))
            }
        }
        .onChange(of: viewModel.activeRecommendationLanguage) { _, language in
            let code = language?.rawValue ?? ""
            if selectedRecommendationLanguageCode != code {
                selectedRecommendationLanguageCode = code
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
                    LazyHStack(spacing: 16) {
                        ForEach(viewModel.incompleteSessions) { session in
                            if let song = session.song {
                                SongSuggestionCard(song: song) {
                                    selectedSong = song
                                }
                            }
                        }
                    }
                    .scrollTargetLayout()
                }
                .scrollTargetBehavior(.viewAligned)
                .scrollClipDisabled()
            }
        }
    }

    private var recommendedForYouSection: some View {
        CustomSectionView(
            header: "Recommended For You",
            headerSubtitle: recommendationLanguageSubtitle
        ) {
            if viewModel.recommendationPhase != .idle {
                RecommendationSectionSkeleton(statusMessage: viewModel.recommendationStatusMessage)
            } else if viewModel.recommendationSongs.isEmpty {
                RecommendationEmptyView()
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(viewModel.recommendationSongs) { song in
                            SongSuggestionCard(song: song) {
                                selectedSong = song
                            }
                        }
                    }
                    .scrollTargetLayout()
                }
                .scrollTargetBehavior(.viewAligned)
                .scrollClipDisabled()
            }
        } trailingContent: {
            if viewModel.studyLanguages.count > 1, let title = recommendationLanguageButtonTitle {
                HeaderButtonMenu(
                    title,
                    icon: "globe",
                    size: .small,
                    style: .bordered
                ) {
                    ForEach(viewModel.studyLanguages) { studyLanguage in
                        let language = studyLanguage.language
                        Button {
                            selectRecommendationLanguage(language)
                        } label: {
                            HStack {
                                Text(studyLanguage.displayName)
                                if viewModel.activeRecommendationLanguage == language {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var favoriteSongsSection: some View {
        if !viewModel.favoriteSongs.isEmpty {
            CustomSectionView(header: "Favorite Songs") {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 16) {
                        ForEach(viewModel.favoriteSongs) { session in
                            if let song = session.song {
                                SongSuggestionCard(song: song) {
                                    selectedSong = song
                                }
                            }
                        }
                    }
                    .scrollTargetLayout()
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
                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2),
                    spacing: 12
                ) {
                    ForEach(viewModel.searchResults) { song in
                        SongSuggestionCard(song: song) {
                            selectedSong = song
                        }
                    }
                }
                .padding(.vertical, 8)
            }
        } else {
            CustomSectionView(header: "Search Results") {
                ContentUnavailableView(
                    String(
                        localized: "music.search.empty.title",
                        defaultValue: "No results found"
                    ),
                    systemImage: "magnifyingglass",
                    description: Text(
                        String(
                            localized: "music.search.empty.subtitle",
                            defaultValue: "Try a different song title or artist."
                        )
                    )
                )
                .padding(.vertical, 24)
            }
        }
    }

    // MARK: - History Section

    @ViewBuilder
    private var historySection: some View {
        if !viewModel.completedSessions.isEmpty {
            CustomSectionView(header: "History") {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 12) {
                        ForEach(viewModel.completedSessions) { session in
                            if let song = session.song {
                                SongSuggestionCard(song: song) {
                                    selectedSong = song
                                }
                            }
                        }
                    }
                    .scrollTargetLayout()
                }
                .scrollTargetBehavior(.viewAligned)
                .scrollClipDisabled()
            }
        }
    }
}

private extension MusicDiscoveringView {
    func selectRecommendationLanguage(_ language: InputLanguage) {
        guard viewModel.activeRecommendationLanguage != language else { return }
        if selectedRecommendationLanguageCode != language.rawValue {
            selectedRecommendationLanguageCode = language.rawValue
        } else {
            viewModel.handle(.selectRecommendationLanguage(language))
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

private struct RecommendationSectionSkeleton: View {
    let statusMessage: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let statusMessage {
                Text(statusMessage)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 4)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(0..<4, id: \.self) { _ in
                        SongCardSkeleton()
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.viewAligned)
            .scrollClipDisabled()
        }
    }
}

private struct RecommendationEmptyView: View {
    var body: some View {
        ContentUnavailableView(
            String(
                localized: "music.recommendations.empty.title",
                defaultValue: "No recommendations yet"
            ),
            systemImage: "sparkles",
            description: Text(
                String(
                    localized: "music.recommendations.empty.subtitle",
                    defaultValue: "Try generating a lesson to seed new songs."
                )
            )
        )
        .padding(.vertical, 24)
    }
}

// MARK: - Previews

#Preview("Skeleton Loading") {
    RecommendationSectionSkeleton(statusMessage: "Generating recommendations")
        .padding()
        .groupedBackground()
}

#Preview("Single Card Skeleton") {
    SongCardSkeleton()
        .padding()
        .groupedBackground()
}
