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
    @StateObject private var subscriptionService = SubscriptionService.shared
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

    private var analyticsLanguageCode: String? {
        viewModel.activeRecommendationLanguage?.rawValue ?? selectedRecommendationLanguageCode.nilIfEmpty
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
                .if(isPad) { view in
                    view
                        .frame(maxWidth: 550, alignment: .center)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            } else {
                MusicAuthenticationView()
                    .onDisappear {
                        viewModel.handle(.loadData)
                    }
            }
        }
        .groupedBackground()
        .navigation(
            title: Loc.Discover.title,
            trailingContent: {
                contentPicker
            },
            bottomContent: {
                Text(Loc.MusicDiscovering.View.description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

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
                AnalyticsService.shared.logEvent(
                    .musicDiscoveringOpened,
                    parameters: [
                        "authorized": 1,
                        "language_code": analyticsLanguageCode ?? "unknown",
                        "has_cached_selection": selectedRecommendationLanguageCode.isNotEmpty ? 1 : 0
                    ]
                )
                viewModel.handle(.loadData)
            } else {
                AnalyticsService.shared.logEvent(
                    .musicDiscoveringOpened,
                    parameters: [
                        "authorized": 0,
                        "language_code": analyticsLanguageCode ?? "unknown"
                    ]
                )
            }
        }
    }

    // MARK: - Sections

    @ViewBuilder
    private var notFinishedSection: some View {
        if !viewModel.incompleteSessions.isEmpty {
            CustomSectionView(header: Loc.MusicDiscovering.View.Section.notFinished) {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 16) {
                        ForEach(viewModel.incompleteSessions) { session in
                            if let song = session.song {
                                SongSuggestionCard(song: song) {
                                    let sessionID = session.session?.id.uuidString ?? session.id?.uuidString
                                    selectSong(
                                        song,
                                        context: "incomplete",
                                        sessionID: sessionID,
                                        isFavorite: session.isFavorite
                                    )
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
            header: Loc.MusicDiscovering.View.Section.recommendedForYou,
            headerSubtitle: recommendationLanguageSubtitle
        ) {
            if viewModel.recommendationPhase != .idle {
                RecommendationSectionSkeleton(statusMessage: viewModel.recommendationStatusMessage)
            } else if viewModel.recommendationSongs.isEmpty {
                RecommendationEmptyView()
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 16) {
                        ForEach(Array(viewModel.recommendationSongs.enumerated()), id: \.element.id) { index, song in
                            SongSuggestionCard(song: song) {
                                selectSong(
                                    song,
                                    context: "recommendations",
                                    position: index
                                )
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
            CustomSectionView(header: Loc.MusicDiscovering.View.Section.favoriteSongs) {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 16) {
                        ForEach(viewModel.favoriteSongs) { session in
                            if let song = session.song {
                                SongSuggestionCard(song: song) {
                                    let sessionID = session.session?.id.uuidString ?? session.id?.uuidString
                                    selectSong(
                                        song,
                                        context: "favorites",
                                        sessionID: sessionID,
                                        isFavorite: session.isFavorite
                                    )
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
        let width = isPad
        ? 550 / 2 - 6 - 32
        : UIScreen.main.fixedCoordinateSpace.bounds.width / 2 - 6 - 32
        if viewModel.isSearching {
            CustomSectionView(header: Loc.MusicDiscovering.View.Search.loading) {
                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2),
                    spacing: 12
                ) {
                    ForEach(0..<6) { index in
                        VStack(alignment: .leading, spacing: 8) {
                            ShimmerView(width: width, height: width)
                            ShimmerView(width: width - 20, height: 20)
                            ShimmerView(width: width - 50, height: 16)
                        }
                    }
                }
                .padding(.vertical, 8)
            }
        } else if !viewModel.searchResults.isEmpty {
            CustomSectionView(header: Loc.MusicDiscovering.View.Search.resultsTitle) {
                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2),
                    spacing: 12
                ) {
                    ForEach(Array(viewModel.searchResults.enumerated()), id: \.element.id) { index, song in
                        SongSuggestionCard(
                            song: song,
                            size: .init(width: width, height: width)
                        ) {
                            selectSong(
                                song,
                                context: "search",
                                position: index
                            )
                        }
                    }
                }
                .padding(.vertical, 8)
            }
        } else {
            CustomSectionView(header: Loc.MusicDiscovering.View.Search.resultsTitle) {
                ContentUnavailableView(
                    Loc.MusicDiscovering.View.Search.emptyTitle,
                    systemImage: "magnifyingglass",
                    description: Text(
                        Loc.MusicDiscovering.View.Search.emptySubtitle
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
            CustomSectionView(header: Loc.MusicDiscovering.View.Section.history) {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 12) {
                        ForEach(viewModel.completedSessions) { session in
                            if let song = session.song {
                                SongSuggestionCard(song: song) {
                                    let sessionID = session.session?.id.uuidString ?? session.id?.uuidString
                                    selectSong(
                                        song,
                                        context: "history",
                                        sessionID: sessionID,
                                        isFavorite: session.isFavorite
                                    )
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

    func selectSong(
        _ song: Song,
        context: String,
        sessionID: String? = nil,
        position: Int? = nil,
        isFavorite: Bool? = nil
    ) {
        logSongSelection(
            song,
            context: context,
            sessionID: sessionID,
            position: position,
            isFavorite: isFavorite
        )

        guard subscriptionService.isProUser else {
            AlertCenter.shared.showAlert(with: .init(
                title: Loc.Subscription.ProFeatures.aiLessons,
                message: Loc.Subscription.ProFeatures.aiLessonsDescription,
                actionText: Loc.Actions.ok,
                additionalActionText: Loc.Subscription.Paywall.upgradeToPro,
                action: {},
                additionalAction: {
                    PaywallService.shared.presentPaywall(for: .aiLessons)
                }
            ))
            return
        }

        selectedSong = song
    }

    func logSongSelection(
        _ song: Song,
        context: String,
        sessionID: String? = nil,
        position: Int? = nil,
        isFavorite: Bool? = nil
    ) {
        var parameters: [String: Any] = [
            "song_id": song.serviceId,
            "context": context,
            "authorized": isAppleMusicAuthorized ? 1 : 0,
            "is_premium": subscriptionService.isProUser ? 1 : 0
        ]

        if let cefr = song.cefrLevel?.rawValue {
            parameters["cefr_level"] = cefr
        }

        if let language = analyticsLanguageCode {
            parameters["language_code"] = language
        }

        if let sessionID {
            parameters["session_id"] = sessionID
        }

        if let position {
            parameters["position"] = position
        }

        if isSearchActive {
            parameters["query_length"] = viewModel.searchText.count
        }

        if let isFavorite {
            parameters["is_favorite"] = isFavorite ? 1 : 0
        }

        AnalyticsService.shared.logEvent(.musicDiscoveringSongSelected, parameters: parameters)
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
            Loc.MusicDiscovering.View.Recommendations.emptyTitle,
            systemImage: "sparkles",
            description: Text(
                Loc.MusicDiscovering.View.Recommendations.emptySubtitle
            )
        )
        .padding(.vertical, 24)
    }
}

// MARK: - Previews

#Preview("Skeleton Loading") {
    RecommendationSectionSkeleton(statusMessage: Loc.MusicDiscovering.Status.Recommendations.generating)
        .padding()
        .groupedBackground()
}

#Preview("Single Card Skeleton") {
    SongCardSkeleton()
        .padding()
        .groupedBackground()
}
