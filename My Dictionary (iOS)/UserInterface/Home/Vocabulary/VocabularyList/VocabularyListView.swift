//
//  VocabularyListView.swift
//  My Dictionary
//
//  Created by Alexander Riakhin on 8/9/25.
//

import SwiftUI
import StoreKit

struct VocabularyListView: View {

    @Environment(\.requestReview) var requestReview

    @AppStorage(UDKeys.isShowingRating)
    var isShowingRating: Bool = true

    @AppStorage(UDKeys.lastRatingRequestDate)
    var lastRatingRequestDate: TimeInterval = .zero

    @AppStorage(UDKeys.ratingRequestCount)
    var ratingRequestCount: Int = 0

    @AppStorage(UDKeys.hasRatedApp)
    var hasRatedApp: Bool = false

    @StateObject private var dictionaryService = DictionaryService.shared
    @StateObject private var collectionsManager = WordCollectionsManager.shared
    @StateObject private var navigationManager = NavigationManager.shared
    @State private var showRatingBanner = false
    @State private var searchText = ""
    @State private var sortingState: SortingCase = .latest

    @ObservedObject private var wordListViewModel: WordListViewModel
    @ObservedObject private var idiomListViewModel: IdiomListViewModel

    init(
        wordListViewModel: WordListViewModel,
        idiomListViewModel: IdiomListViewModel
    ) {
        self.wordListViewModel = wordListViewModel
        self.idiomListViewModel = idiomListViewModel
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                wordCollectionsSection
                wordsSection
                idiomsSection
                ratingBannerView
            }
            .padding(.horizontal, 16)
            .if(isPad) { view in
                view
                    .frame(maxWidth: 550, alignment: .center)
            }
        }
        .navigation(
            title: Loc.Onboarding.myDictionary,
            mode: .large,
            trailingContent: {
                HeaderButtonMenu(icon: "arrow.up.arrow.down") {
                    // Words sorting
                    Picker(Loc.Words.sort, selection: $sortingState) {
                        ForEach(SortingCase.allCases, id: \.self) { item in
                            Text(item.displayName)
                                .tag(item)
                        }
                    }
                    .onChange(of: sortingState) {
                        wordListViewModel.sortingState = sortingState
                        idiomListViewModel.sortingState = sortingState
                    }
                }

                if AuthenticationService.shared.isSignedIn {
                    HeaderButton(icon: "person.2") {
                        wordListViewModel.output.send(.showSharedDictionaries)
                    }
                    .hideIfOffline()
                    
                }
            },
            bottomContent: {
                VStack(spacing: 12) {
                    InputView.searchView(
                        Loc.Words.search,
                        searchText: $searchText
                    )
                    VocabularyListFilterView(
                        wordListViewModel: wordListViewModel,
                        idiomListViewModel: idiomListViewModel
                    )
                }
            }
        )
        .onAppear {
            AnalyticsService.shared.logEvent(.wordsListOpened)
            checkAndShowRatingBanner()
        }
        .onChange(of: wordListViewModel.words.count) {
            checkAndShowRatingBanner()
        }
        .onChange(of: searchText) {
            wordListViewModel.searchText = searchText
            idiomListViewModel.searchText = searchText
        }
    }

    // MARK: - Word Collections Section

    private var wordCollectionsSection: some View {
        Group {
            if collectionsManager.hasCollections {
                CustomSectionView(
                    header: "Word Collections",
                    footer: "\(collectionsManager.collections.count) collections available"
                ) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(collectionsManager.collections.prefix(5)) { collection in
                                WordCollectionPreviewCard(collection: collection)
                            }
                        }
                        .scrollTargetLayout()
                    }
                    .scrollTargetBehavior(.viewAligned)
                    .scrollClipDisabled()
                    .padding(.bottom, 12)
                } trailingContent: {
                    HeaderButton(Loc.Actions.viewAll, size: .small, style: .borderedProminent) {
                        navigationManager.navigationPath.append(NavigationDestination.wordCollections)
                    }
                }
            }
        }
    }

    // MARK: - Words Section

    private var wordsSection: some View {
        CustomSectionView(
            header: wordListViewModel.filterStateTitle,
            footer: wordListViewModel.wordsCount,
            hPadding: 0
        ) {
            if wordListViewModel.wordsFiltered.isNotEmpty {
                ListWithDivider(wordListViewModel.wordsFiltered) { wordModel in
                    WordListCellView(word: wordModel)
                        .id(wordModel)
                        .onTap {
                            wordListViewModel.output.send(.showWordDetails(wordModel))
                        }
                        .contextMenu {
                            if AuthenticationService.shared.isSignedIn {
                                Button {
                                    wordListViewModel.output.send(.showAddExistingWordToShared(wordModel))
                                } label: {
                                    Label(Loc.Words.addToSharedDictionary, systemImage: "person.2")
                                }
                            }
                            Button(role: .destructive) {
                                wordListViewModel.handle(.deleteWord(word: wordModel))
                            } label: {
                                Label(Loc.Actions.delete, systemImage: "trash")
                                    .tint(.red)
                            }
                        }
                }
            } else {
                ContentUnavailableView(
                    wordListViewModel.filterState.emptyStateTitle(for: .words),
                    systemImage: wordListViewModel.filterState.emptyStateIcon(for: .words),
                    description: Text(wordListViewModel.filterState.emptyStateDescription(for: .words))
                )
                .padding(.vertical, 24)
            }
        } trailingContent: {
            HeaderButton(Loc.Words.addWord, icon: "plus", size: .small, style: .borderedProminent) {
                AnalyticsService.shared.logEvent(.addWordTapped)
                wordListViewModel.output.send(.showAddWord(searchText))
            }
        }
        .animation(.default, value: wordListViewModel.filterState)
        .animation(.default, value: wordListViewModel.sortingState)
    }

    // MARK: - Idioms Section

    private var idiomsSection: some View {
        CustomSectionView(
            header: idiomListViewModel.filterStateTitle,
            footer: idiomListViewModel.idiomsCount,
            hPadding: 0
        ) {
            if idiomListViewModel.idiomsFiltered.isNotEmpty {
                ListWithDivider(idiomListViewModel.idiomsFiltered) { idiomModel in
                    Button {
                        idiomListViewModel.output.send(.showIdiomDetails(idiomModel))
                    } label: {
                        WordListCellView(word: idiomModel)
                            .id(idiomModel)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button(role: .destructive) {
                            idiomListViewModel.handle(.deleteIdiom(idiom: idiomModel))
                        } label: {
                            Label(Loc.Actions.delete, systemImage: "trash")
                                .tint(.red)
                        }
                    }
                }
            } else {
                ContentUnavailableView(
                    idiomListViewModel.filterState.emptyStateTitle(for: .idioms),
                    systemImage: idiomListViewModel.filterState.emptyStateIcon(for: .idioms),
                    description: Text(idiomListViewModel.filterState.emptyStateDescription(for: .idioms))
                )
                .padding(.vertical, 24)
            }
        } trailingContent: {
            HeaderButton(
                Loc.Words.addIdiom,
                icon: "plus",
                size: .small,
                style: .borderedProminent
            ) {
                idiomListViewModel.output.send(.showAddIdiom(searchText))
            }
        }
        .animation(.default, value: idiomListViewModel.filterState)
    }

    // MARK: - Rating Banner View

    @ViewBuilder
    private var ratingBannerView: some View {
        if shouldShowRatingBanner {
            RatingBanner(
                wordCount: wordListViewModel.words.count,
                onRate: {
                    requestReview()
                    hasRatedApp = true
                    showRatingBanner = false
                    AnalyticsService.shared.logEvent(.ratingBannerTapped)
                },
                onDismiss: {
                    showRatingBanner = false
                    lastRatingRequestDate = Date.now.timeIntervalSince1970
                    ratingRequestCount += 1
                    AnalyticsService.shared.logEvent(.ratingBannerDismissed)
                }
            )
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    // MARK: - Rating Banner Logic
    
    private var shouldShowRatingBanner: Bool {
        guard isShowingRating && !hasRatedApp else { return false }
        
        // Only show if user has substantial vocabulary
        guard wordListViewModel.words.count >= 25 else { return false }

        // Don't show too frequently
        let daysSinceLastRequest = Calendar.current.dateComponents(
            [.day],
            from: Date(timeIntervalSince1970: lastRatingRequestDate),
            to: .now
        ).day ?? 0
        guard daysSinceLastRequest >= 7 else { return false }
        
        // Don't show too many times
        guard ratingRequestCount < 3 else { return false }
        
        // Show banner if conditions are met
        return showRatingBanner
    }
    
    private func checkAndShowRatingBanner() {
        // Add a small delay to ensure smooth animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if shouldShowRatingBanner {
                withAnimation(.easeInOut(duration: 0.6)) {
                    showRatingBanner = true
                }
            }
        }
    }
}

// MARK: - Rating Banner Component

struct RatingBanner: View {
    let wordCount: Int
    let onRate: VoidHandler
    let onDismiss: VoidHandler

    var body: some View {
        CustomSectionView(header: Loc.Words.impressiveVocabulary) {
            VStack(spacing: 16) {
                // Header with achievement message
                VStack(spacing: 8) {
                    Text(Loc.Words.impressiveVocabularyMessage(wordCount))
                        .font(.subheadline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .multilineTextAlignment(.leading)
                }

                // Action buttons
                VStack(spacing: 12) {
                    ActionButton(
                        Loc.Settings.rateApp,
                        systemImage: "star.circle.fill",
                        style: .borderedProminent,
                        action: onRate
                    )
                    ActionButton(Loc.Coffee.maybeLater, action: onDismiss)
                }
            }
        } trailingContent: {
            HeaderButton(
                icon: "xmark.circle.fill",
                size: .small
            ) {
                onDismiss()
            }
        }
    }
}
