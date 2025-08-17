//
//  WordListView.swift
//  My Dictionary
//
//  Created by Alexander Riakhin on 8/9/25.
//

import SwiftUI
import StoreKit

struct WordListView: View {

    typealias ViewModel = WordListViewModel

    @AppStorage(UDKeys.isShowingRating) var isShowingRating: Bool = true
    @AppStorage(UDKeys.lastRatingRequestDate) var lastRatingRequestDate: TimeInterval = Date.distantPast.timeIntervalSince1970
    @AppStorage(UDKeys.ratingRequestCount) var ratingRequestCount: Int = 0
    @AppStorage(UDKeys.hasRatedApp) var hasRatedApp: Bool = false
    @Environment(\.requestReview) var requestReview
    @ObservedObject var viewModel: ViewModel
    @StateObject private var dictionaryService = DictionaryService.shared
    @State private var showRatingBanner = false

    init(viewModel: ViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // MARK: - button to add a word from search input
                if viewModel.filterState == .search && viewModel.wordsFiltered.count < 10 {
                    ActionButton(
                        Loc.Words.addWord.localized(viewModel.searchText.trimmingCharacters(in: .whitespacesAndNewlines)),
                        systemImage: "plus"
                    ) {
                        viewModel.output.send(.showAddWord)
                    }
                }

                // MARK: - Words
                CustomSectionView(
                    header: viewModel.filterStateTitle,
                    footer: viewModel.wordsCount,
                    hPadding: 0
                ) {
                    if viewModel.wordsFiltered.isNotEmpty {
                        ListWithDivider(viewModel.wordsFiltered) { wordModel in
                            WordListCellView(word: wordModel)
                                .id(wordModel.id)
                                .onTap {
                                    viewModel.output.send(.showWordDetails(wordModel))
                                }
                                .contextMenu {
                                    if AuthenticationService.shared.isSignedIn {
                                        Button {
                                            viewModel.output.send(.showAddExistingWordToShared(wordModel))
                                        } label: {
                                            Label(Loc.Words.addToSharedDictionary.localized, systemImage: "person.2")
                                        }
                                    }
                                    Button(role: .destructive) {
                                        viewModel.handle(.deleteWord(word: wordModel))
                                    } label: {
                                        Label(Loc.Actions.delete.localized, systemImage: "trash")
                                    }
                                }
                        }
                    } else {
                        ContentUnavailableView(
                            viewModel.filterState.emptyStateTitle,
                            systemImage: viewModel.filterState.emptyStateIcon,
                            description: Text(viewModel.filterState.emptyStateDescription)
                        )
                        .padding(.vertical, 24)
                    }
                } trailingContent: {
                    HeaderButton(Loc.Words.addWord.localized, icon: "plus", size: .small, style: .borderedProminent) {
                        AnalyticsService.shared.logEvent(.addWordTapped)
                        viewModel.output.send(.showAddWord)
                    }
                }

                // MARK: - Rating Banner
                if shouldShowRatingBanner {
                    RatingBanner(
                        wordCount: viewModel.words.count,
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
            .padding(.horizontal, 16)
        }
        .animation(.default, value: viewModel.wordsFiltered)
        .animation(.default, value: viewModel.filterState)
        .animation(.default, value: viewModel.sortingState)
        .navigation(
            title: Loc.Words.words.localized,
            mode: .large,
            trailingContent: {
                HeaderButtonMenu(icon: "arrow.up.arrow.down") {
                    Picker(Loc.Words.sort.localized, selection: _viewModel.projectedValue.sortingState) {
                        ForEach(SortingCase.allCases, id: \.self) { item in
                            Text(item.rawValue)
                                .tag(item)
                        }
                    }
                    .pickerStyle(.inline)
                }

                if AuthenticationService.shared.isSignedIn {
                    HeaderButton(icon: "person.2") {
                        viewModel.output.send(.showSharedDictionaries)
                    }
                }
            },
            bottomContent: {
                VStack(spacing: 12) {
                    InputView.searchView(
                        Loc.Words.searchWords.localized,
                        searchText: $viewModel.searchText
                    )
                    WordListFilterView(viewModel: viewModel)
                }
            }
        )
        .onAppear {
            AnalyticsService.shared.logEvent(.wordsListOpened)
            checkAndShowRatingBanner()
        }
        .onChange(of: viewModel.words.count) { _ in
            checkAndShowRatingBanner()
        }
    }
    
    // MARK: - Rating Banner Logic
    
    private var shouldShowRatingBanner: Bool {
        guard isShowingRating && !hasRatedApp else { return false }
        
        // Only show if user has substantial vocabulary
        guard viewModel.words.count >= 25 else { return false }
        
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
        CustomSectionView(header: Loc.Words.impressiveVocabulary.localized) {
            VStack(spacing: 16) {
                // Header with achievement message
                VStack(spacing: 8) {
                    Text(Loc.Words.impressiveVocabularyMessage.localized(wordCount))
                        .font(.subheadline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .multilineTextAlignment(.leading)
                }

                // Action buttons
                VStack(spacing: 12) {
                    ActionButton(
                        Loc.Settings.rateApp.localized,
                        systemImage: "star.circle.fill",
                        style: .borderedProminent,
                        action: onRate
                    )
                    ActionButton(Loc.Coffee.maybeLater.localized, action: onDismiss)
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
