//
//  AddCollectionToDictionaryView.swift
//  My Dictionary
//
//  Created by Alexander Riakhin on 9/12/25.
//

import SwiftUI
import StoreKit

struct AddCollectionToDictionaryView: View {
    let collection: WordCollection
    @Environment(\.dismiss) private var dismiss
    @State private var selectedWords: Set<String> = []
    @State private var isAdding = false
    @State private var showSuccessAlert = false
    @State private var addedWordsCount = 0
    @State private var duplicateWordsCount = 0
    
    // MARK: - StoreKit
    @Environment(\.requestReview) var requestReview
    
    // MARK: - Rating Request Properties
    @AppStorage(UDKeys.hasRatedApp)
    private var hasRatedApp: Bool = false
    
    @AppStorage(UDKeys.lastRatingRequestDate)
    private var lastRatingRequestDate: TimeInterval = .zero
    
    @AppStorage(UDKeys.ratingRequestCount)
    private var ratingRequestCount: Int = 0
    
    var body: some View {
        ScrollView {
            ListWithDivider(collection.words) { word in
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(word.text)
                            .font(.headline)
                        Text(word.definition)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }

                    Spacer()

                    Image(systemName: selectedWords.contains(word.id) ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(selectedWords.contains(word.id) ? .accent : .secondary)
                }
                .padding(vertical: 12, horizontal: 16)
                .contentShape(Rectangle())
                .onTapGesture {
                    if selectedWords.contains(word.id) {
                        selectedWords.remove(word.id)
                    } else {
                        selectedWords.insert(word.id)
                    }
                }
            }
            .clippedWithBackground(showShadow: true)
            .padding(vertical: 12, horizontal: 16)
        }
        .groupedBackground()
        .navigation(
            title: Loc.WordCollections.addWords,
            mode: .inline,
            trailingContent: {
                HeaderButton(Loc.Actions.cancel, size: .small) {
                    dismiss()
                }
                if selectedWords.isEmpty {
                    AsyncHeaderButton(
                        Loc.WordCollections.addAll,
                        size: .small,
                        style: .borderedProminent
                    ) {
                        try await addAllWords()
                    }
                } else {
                    AsyncHeaderButton(
                        Loc.Actions.add + " (\(selectedWords.count))",
                        size: .small,
                        style: .borderedProminent
                    ) {
                        try await addSelectedWords()
                    }
                }
            },
            bottomContent: {
                Text(Loc.WordCollections.selectWordsDescription(collection.title))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        )
        .alert(Loc.WordCollections.importComplete, isPresented: $showSuccessAlert) {
            Button(Loc.Actions.ok) {
                // Request review after successful import
                requestReviewIfAppropriate()
                dismiss()
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

    // MARK: - Actions

    private func addAllWords() async throws {
        AnalyticsService.shared.logEvent(.wordCollectionImportStarted, parameters: [
            "collection_id": collection.id,
            "collection_title": collection.title,
            "word_count": collection.words.count,
            "user_subscription_status": SubscriptionService.shared.isProUser ? "pro" : "free"
        ])

        let result = try await WordCollectionImportService.shared.importAllWords(from: collection)

        await MainActor.run {
            addedWordsCount = result.addedCount
            duplicateWordsCount = result.duplicateCount
            isAdding = false
            showSuccessAlert = true
        }

        // Log import completion analytics
        AnalyticsService.shared.logEvent(.wordCollectionImportCompleted, parameters: [
            "collection_id": collection.id,
            "collection_title": collection.title,
            "words_added": result.addedCount,
            "duplicates_found": result.duplicateCount,
            "user_subscription_status": SubscriptionService.shared.isProUser ? "pro" : "free"
        ])
    }

    private func addSelectedWords() async throws {
        AnalyticsService.shared.logEvent(.wordCollectionImportStarted, parameters: [
            "collection_id": collection.id,
            "collection_title": collection.title,
            "word_count": selectedWords.count,
            "user_subscription_status": SubscriptionService.shared.isProUser ? "pro" : "free"
        ])

        let result = try await WordCollectionImportService.shared.importWords(
            from: collection,
            selectedWordIds: selectedWords
        )

        await MainActor.run {
            addedWordsCount = result.addedCount
            duplicateWordsCount = result.duplicateCount
            isAdding = false
            showSuccessAlert = true
        }

        // Log import completion analytics
        AnalyticsService.shared.logEvent(.wordCollectionImportCompleted, parameters: [
            "collection_id": collection.id,
            "collection_title": collection.title,
            "words_added": result.addedCount,
            "duplicates_found": result.duplicateCount,
            "user_subscription_status": SubscriptionService.shared.isProUser ? "pro" : "free"
        ])
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
