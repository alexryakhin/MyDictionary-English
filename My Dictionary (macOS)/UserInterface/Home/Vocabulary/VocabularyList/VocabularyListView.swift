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

    @AppStorage(UDKeys.isShowingRating) private var isShowingRating: Bool = true
    @AppStorage(UDKeys.lastRatingRequestDate) private var lastRatingRequestDate: TimeInterval = .zero
    @AppStorage(UDKeys.ratingRequestCount) private var ratingRequestCount: Int = 0
    @AppStorage(UDKeys.hasRatedApp) private var hasRatedApp: Bool = false

    @StateObject private var wordListViewModel = WordListViewModel()
    @StateObject private var idiomListViewModel = IdiomListViewModel()
    @StateObject private var dictionaryService = DictionaryService.shared
    @StateObject private var sideBarManager = SideBarManager.shared

    @State private var showRatingBanner = false
    @State private var showAddWord = false
    @State private var showAddIdiom = false
    @State private var wordToAddToSharedDictionary: CDWord?
    @State private var searchText = ""
    @State private var sortingState: SortingCase = .latest

    var body: some View {
        ScrollViewWithCustomNavBar {
            VStack(spacing: 16) {
                wordsSection
                idiomsSection
                ratingBannerView
            }
            .padding(12)
        } navigationBar: {
            VocabularyListFilterView(
                wordListViewModel: wordListViewModel,
                idiomListViewModel: idiomListViewModel
            )
            .padding(.vertical, 12)
        }
        .groupedBackground()
        .navigationTitle(Loc.Onboarding.myDictionary)
        .searchable(text: $searchText, prompt: Loc.Words.search)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                // Words sorting
                Menu {
                    Picker(Loc.Words.sort, selection: $sortingState) {
                        ForEach(SortingCase.allCases, id: \.self) { item in
                            Text(item.displayName)
                                .tag(item)
                        }
                    }
                    .pickerStyle(.inline)
                } label: {
                    Image(systemName: "arrow.up.arrow.down")
                }
                .onChange(of: sortingState) {
                    wordListViewModel.sortingState = sortingState
                    idiomListViewModel.sortingState = sortingState
                }

                // Add Word button
                Button {
                    AnalyticsService.shared.logEvent(.addWordTapped)
                    showAddWord.toggle()
                } label: {
                    Image(systemName: "plus")
                }
                .help(Loc.Words.addWord)
            }
        }
        .onAppear {
            AnalyticsService.shared.logEvent(.wordsListOpened)
            checkAndShowRatingBanner()
        }
        .onChange(of: wordListViewModel.words.count) { _ in
            checkAndShowRatingBanner()
        }
        .onChange(of: searchText) { newValue in
            wordListViewModel.searchText = newValue
            idiomListViewModel.searchText = newValue
        }
        .sheet(isPresented: $showAddWord) {
            AddWordView(inputWord: searchText, selectedDictionaryId: nil)
        }
        .sheet(isPresented: $showAddIdiom) {
            AddIdiomView(inputIdiom: searchText)
        }
        .sheet(item: $wordToAddToSharedDictionary) { word in
            AddExistingWordToSharedView(word: word)
        }
    }

    // MARK: - Words

    private var wordsSection: some View {
        CustomSectionView(
            header: wordListViewModel.filterStateTitle,
            footer: wordListViewModel.wordsCount,
            hPadding: 0
        ) {
            if wordListViewModel.wordsFiltered.isNotEmpty {
                ListWithDivider(
                    wordListViewModel.wordsFiltered,
                    dividerLeadingPadding: .zero,
                    dividerTrailingPadding: .zero
                ) { wordModel in
                    WordListCellView(word: wordModel)
                        .id(wordModel.id)
                        .onTap {
                            sideBarManager.selectedWord = wordModel
                        }
                        .contextMenu {
                            if AuthenticationService.shared.isSignedIn {
                                Button {
                                    wordToAddToSharedDictionary = wordModel
                                } label: {
                                    Label(Loc.Words.addToSharedDictionary, systemImage: "person.2")
                                }
                            }
                            Button(role: .destructive) {
                                wordListViewModel.handle(.deleteWord(word: wordModel))
                            } label: {
                                Label(Loc.Actions.delete, systemImage: "trash")
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
                showAddWord = true
                AnalyticsService.shared.logEvent(.addWordTapped)
            }
        }
        .animation(.default, value: wordListViewModel.wordsFiltered)
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
                ListWithDivider(
                    idiomListViewModel.idiomsFiltered,
                    dividerLeadingPadding: .zero,
                    dividerTrailingPadding: .zero
                ) { idiomModel in
                    Button {
                        sideBarManager.selectedIdiom = idiomModel
                    } label: {
                        IdiomListCellView(idiom: idiomModel)
                            .id(idiomModel.id)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button(role: .destructive) {
                            idiomListViewModel.handle(.deleteIdiom(idiom: idiomModel))
                        } label: {
                            Label(Loc.Actions.delete, systemImage: "trash")
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
            HeaderButton(Loc.Words.addIdiom, icon: "plus", size: .small, style: .borderedProminent) {
                showAddIdiom = true
            }
        }
        .animation(.default, value: idiomListViewModel.idiomsFiltered)
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
            Button {
                onDismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    RatingBanner(
        wordCount: 50,
        onRate: {},
        onDismiss: {}
    )
    .padding()
}
