//
//  WordListView.swift
//  My Dictionary
//
//  Created by Alexander Riakhin on 8/9/25.
//

import SwiftUI
import StoreKit

struct WordListView: View {
    @Environment(\.requestReview) var requestReview

    @AppStorage(UDKeys.isShowingRating) private var isShowingRating: Bool = true
    @AppStorage(UDKeys.lastRatingRequestDate) private var lastRatingRequestDate: TimeInterval = Date.distantPast.timeIntervalSince1970
    @AppStorage(UDKeys.ratingRequestCount) private var ratingRequestCount: Int = 0
    @AppStorage(UDKeys.hasRatedApp) private var hasRatedApp: Bool = false

    @StateObject private var viewModel = WordListViewModel()
    @StateObject private var dictionaryService = DictionaryService.shared
    @StateObject private var sideBarManager = SideBarManager.shared

    @State private var showRatingBanner = false
    @State private var showAddWordWindow = false

    var body: some View {
        ScrollViewWithCustomNavBar {
            VStack(spacing: 16) {
                // MARK: - button to add a word from search input
                if viewModel.filterState == .search && viewModel.wordsFiltered.count < 10 {
                    ActionButton(
                        "Add '\(viewModel.searchText.trimmingCharacters(in: .whitespacesAndNewlines))'",
                        systemImage: "plus"
                    ) {
                        // This will be handled by the parent view
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
                                    sideBarManager.selectedWord = wordModel
                                }
                                .contextMenu {
                                    if AuthenticationService.shared.isSignedIn {
                                        Button {
                                            // This will be handled by the parent view
                                        } label: {
                                            Label("Add to Shared Dictionary", systemImage: "person.2")
                                        }
                                    }
                                    Button(role: .destructive) {
                                        viewModel.handle(.deleteWord(word: wordModel))
                                    } label: {
                                        Label("Delete", systemImage: "trash")
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
                    HeaderButton("Add Word", icon: "plus", size: .small, style: .borderedProminent) {
                        AnalyticsService.shared.logEvent(.addWordTapped)
                        // This will be handled by the parent view
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
            .padding(12)
        } navigationBar: {
            WordListFilterView(viewModel: viewModel)
                .padding(.vertical, 12)
        }
        .groupedBackground()
        .animation(.default, value: viewModel.wordsFiltered)
        .animation(.default, value: viewModel.filterState)
        .animation(.default, value: viewModel.sortingState)
        .navigationTitle("Words")
        .searchable(text: $viewModel.searchText, prompt: "Search words...")
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                // Sort button
                Menu {
                    Picker("Sort", selection: $viewModel.sortingState) {
                        ForEach(SortingCase.allCases, id: \.self) { item in
                            Text(item.rawValue)
                                .tag(item)
                        }
                    }
                } label: {
                    Image(systemName: "arrow.up.arrow.down")
                }
                
                // Shared Dictionaries button
                if AuthenticationService.shared.isSignedIn {
                    Button {
                        // This will be handled by the parent view
                    } label: {
                        Image(systemName: "person.2")
                    }
                    .help("Shared Dictionaries")
                }
                
                // Add Word button
                Button {
                    AnalyticsService.shared.logEvent(.addWordTapped)
                    showAddWordWindow.toggle()
                } label: {
                    Image(systemName: "plus")
                }
                .help("Add Word")
            }
        }
        .onAppear {
            AnalyticsService.shared.logEvent(.wordsListOpened)
            checkAndShowRatingBanner()
        }
        .onChange(of: viewModel.words.count) { _ in
            checkAndShowRatingBanner()
        }
        .sheet(isPresented: $showAddWordWindow) {
            AddWordView(inputWord: viewModel.searchText, selectedDictionaryId: nil)
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
        CustomSectionView(header: "Impressive Vocabulary!") {
            VStack(spacing: 16) {
                // Header with achievement message
                VStack(spacing: 8) {
                    Text("You've built a collection of **\(wordCount) words**! Your dedication to learning is inspiring.")
                        .font(.subheadline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .multilineTextAlignment(.leading)
                }

                // Action buttons
                VStack(spacing: 12) {
                    ActionButton(
                        "Rate App",
                        systemImage: "star.circle.fill",
                        style: .borderedProminent,
                        action: onRate
                    )
                    ActionButton("Maybe Later", action: onDismiss)
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
