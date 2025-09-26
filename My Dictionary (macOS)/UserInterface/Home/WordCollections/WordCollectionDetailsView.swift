//
//  WordCollectionDetailsView.swift
//  My Dictionary
//
//  Created by AI Assistant on 1/27/25.
//

import SwiftUI
import StoreKit

struct WordCollectionDetailsView: View {
    
    // MARK: - Properties
    
    let originalCollection: WordCollection
    @StateObject private var viewModel: WordCollectionDetailsViewModel
    @State private var searchText = ""
    @State private var selectedWord: WordCollectionItem?
    @State private var showAddToDictionary = false
    @State private var showSuccessAlert = false
    @State private var addedWordsCount = 0
    @State private var duplicateWordsCount = 0
    @State private var isAddingAll = false
    
    // MARK: - StoreKit
    @Environment(\.requestReview) var requestReview
    
    // MARK: - Rating Request Properties
    @AppStorage(UDKeys.hasRatedApp)
    private var hasRatedApp: Bool = false
    
    @AppStorage(UDKeys.lastRatingRequestDate)
    private var lastRatingRequestDate: TimeInterval = .zero
    
    @AppStorage(UDKeys.ratingRequestCount)
    private var ratingRequestCount: Int = 0
    
    // MARK: - Initialization
    
    init(collection: WordCollection) {
        self.originalCollection = collection
        self._viewModel = StateObject(wrappedValue: WordCollectionDetailsViewModel(collection: collection))
    }
    
    // MARK: - Body
    
    var body: some View {
        ScrollViewWithCustomNavBar {
            LazyVStack(spacing: 16) {
                // Collection header
                collectionHeader
                
                // Words list
                wordsSection
            }
            .padding(.horizontal, 16)
            .if(isPad) { view in
                view
                    .frame(maxWidth: 550, alignment: .center)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        } navigationBar: {
            NavigationBarView(
                title: viewModel.collection.title,
                mode: .inline,
                showsDismissButton: true,
                trailingContent: {
                    HeaderButton(
                        Loc.WordCollections.addAll,
                        size: .small,
                        style: .borderedProminent
                    ) {
                        AnalyticsService.shared.logEvent(.wordCollectionImportStarted, parameters: [
                            "collection_id": originalCollection.id,
                            "collection_title": originalCollection.title,
                            "word_count": originalCollection.words.count,
                            "user_subscription_status": SubscriptionService.shared.isProUser ? "pro" : "free"
                        ])
                        addAllWords()
                    }
                    .disabled(isAddingAll)
                },
                bottomContent: {
                    InputView.searchView(
                        Loc.WordCollections.searchWords,
                        searchText: $searchText
                    )
                }
            )
        }
        .groupedBackground()
        .onAppear {
            AnalyticsService.shared.logEvent(.wordCollectionDetailsViewed, parameters: [
                "collection_id": originalCollection.id,
                "collection_title": originalCollection.title,
                "collection_level": originalCollection.level.rawValue,
                "collection_language": originalCollection.languageCode,
                "is_premium": originalCollection.isPremium,
                "is_featured": originalCollection.isFeatured,
                "word_count": originalCollection.words.count
            ])
        }
        .sheet(isPresented: $showAddToDictionary) {
            AddCollectionToDictionaryView(collection: viewModel.collection)
        }
        .sheet(item: $selectedWord) { word in
            WordCollectionItemDetailsView(word: word, collection: viewModel.collection)
        }
        .alert(Loc.WordCollections.importComplete, isPresented: $showSuccessAlert) {
            Button(Loc.Actions.ok) {
                // Request review after successful import
                requestReviewIfAppropriate()
            }
        } message: {
            if duplicateWordsCount > 0 {
                Text(Loc.WordCollections.importSuccessWithDuplicates(
                    Loc.Plurals.Words.wordsCount(addedWordsCount),
                    Loc.Plurals.Words.wordsCount(duplicateWordsCount)
                ))
            } else {
                Text(Loc.WordCollections.importSuccess(Loc.Plurals.Words.wordsCount(addedWordsCount)))
            }
        }
    }
    
    // MARK: - Collection Header
    
    private var collectionHeader: some View {
        CustomSectionView(header: viewModel.collection.title) {
            VStack(alignment: .leading, spacing: 16) {
                // Collection info
                VStack(alignment: .leading, spacing: 8) {
                    if let description = viewModel.collection.description {
                        Text(description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        TagView(
                            text: viewModel.collection.wordCountText,
                            color: .blue,
                            size: .small
                        )
                        TagView(
                            text: viewModel.collection.level.displayName,
                            color: viewModel.collection.level.color,
                            size: .small
                        )

                        Spacer()
                    }
                }
                
                // Add to dictionary button
                ActionButton(
                    Loc.WordCollections.addToMyDictionary,
                    systemImage: "plus.circle.fill",
                    style: .borderedProminent
                ) {
                    showAddToDictionary = true
                }
                
                // Translation button (only show if locale is not English)
                if Locale.current.language.languageCode?.identifier != viewModel.collection.languageCode {
                    AsyncActionButton(
                        Loc.WordCollections.translateDefinitions,
                        systemImage: "globe",
                        style: .bordered
                    ) {
                        await viewModel.translateDefinitions()
                    }
                }
            }
        } trailingContent: {
            if viewModel.collection.isPremium {
                Image(systemName: "crown.fill")
                    .foregroundColor(.yellow)
            }
        }
    }
    
    // MARK: - Words Section
    
    private var wordsSection: some View {
        CustomSectionView(
            header: Loc.WordCollections.contains,
            headerFontStyle: .stealth,
            footer: Loc.Plurals.Words.wordsCount(filteredWords.count),
            hPadding: .zero
        ) {
            if filteredWords.isEmpty {
                ContentUnavailableView(
                    Loc.WordCollections.noWordsFound,
                    systemImage: "magnifyingglass",
                    description: Text(Loc.WordCollections.noWordsFoundDescription)
                )
                .padding(.vertical, 24)
            } else {
                ListWithDivider(filteredWords) { word in
                    WordCollectionItemRow(word: word) {
                        selectedWord = word
                    }
                }
            }
        }
    }
    
    // MARK: - Actions
    
    private func addAllWords() {
        isAddingAll = true
        
        Task {
            do {
                let result = try await WordCollectionImportService.shared.importAllWords(from: viewModel.collection)
                
                await MainActor.run {
                    addedWordsCount = result.addedCount
                    duplicateWordsCount = result.duplicateCount
                    isAddingAll = false
                    showSuccessAlert = true
                    
                    // Log import completion analytics
                    AnalyticsService.shared.logEvent(.wordCollectionImportCompleted, parameters: [
                        "collection_id": originalCollection.id,
                        "collection_title": originalCollection.title,
                        "words_added": result.addedCount,
                        "duplicates_found": result.duplicateCount,
                        "user_subscription_status": SubscriptionService.shared.isProUser ? "pro" : "free"
                    ])
                }
            } catch {
                await MainActor.run {
                    isAddingAll = false
                    // Handle error - could show error alert
                    print("Error importing all words: \(error)")
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var filteredWords: [WordCollectionItem] {
        if searchText.isEmpty {
            return viewModel.collection.words
        } else {
            return viewModel.collection.words.filter { word in
                word.text.localizedCaseInsensitiveContains(searchText) ||
                word.definition.localizedCaseInsensitiveContains(searchText) ||
                word.examples.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }
    }
    
    // MARK: - Review Request Logic
    
    private func requestReviewIfAppropriate() {
        // Don't request if user has already rated
        guard !hasRatedApp else { return }
        
        // Don't request too frequently (at least 7 days between requests)
        let daysSinceLastRequest = Calendar.current.dateComponents(
            [.day],
            from: Date(timeIntervalSince1970: lastRatingRequestDate),
            to: .now
        ).day ?? 0
        guard daysSinceLastRequest >= 7 else { return }
        
        // Don't request too many times (max 3 times)
        guard ratingRequestCount < 3 else { return }
        
        // Only request if we successfully added words (not just duplicates)
        guard addedWordsCount > 0 else { return }
        
        // Request the review
        requestReview()
        
        // Update tracking variables
        lastRatingRequestDate = Date.now.timeIntervalSince1970
        ratingRequestCount += 1
        
        // Log analytics event
        AnalyticsService.shared.logEvent(.ratingRequested)
    }
}

#Preview {
    NavigationStack {
        WordCollectionDetailsView(collection: WordCollection(
            title: "Business English",
            words: [
                WordCollectionItem(
                    text: "negotiate",
                    phonetics: "/nɪˈɡoʊʃiˌeɪt/",
                    partOfSpeech: .verb,
                    definition: "To discuss something with someone in order to reach an agreement",
                    examples: ["We need to negotiate a better price.", "The union is negotiating with management."]
                )
            ],
            level: .b2,
            tagValue: "Business",
            languageCode: "en"
        ))
    }
}

