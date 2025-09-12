//
//  WordCollectionDetailsView.swift
//  My Dictionary
//
//  Created by AI Assistant on 1/27/25.
//

import SwiftUI

struct WordCollectionDetailsView: View {
    
    // MARK: - Properties
    
    let collection: WordCollection
    @State private var searchText = ""
    @State private var selectedWord: WordCollectionItem?
    @State private var showAddToDictionary = false
    
    // MARK: - Body
    
    var body: some View {
        ScrollView {
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
            }
        }
        .groupedBackground()
        .navigation(
            title: collection.title,
            mode: .inline,
            showsBackButton: true,
            trailingContent: {
                HeaderButton(
                    "Add All",
                    size: .small,
                    style: .borderedProminent
                ) {
                    showAddToDictionary = true
                }
            },
            bottomContent: {
                InputView.searchView(
                    "Search words",
                    searchText: $searchText
                )
            }
        )
        .sheet(isPresented: $showAddToDictionary) {
            AddCollectionToDictionaryView(collection: collection)
        }
        .sheet(item: $selectedWord) { word in
            WordCollectionItemDetailsView(word: word, collection: collection)
        }
    }
    
    // MARK: - Collection Header
    
    private var collectionHeader: some View {
        CustomSectionView(header: collection.title) {
            VStack(alignment: .leading, spacing: 16) {
                // Collection info
                VStack(alignment: .leading, spacing: 8) {
                    if let description = collection.description {
                        Text(description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        TagView(
                            text: collection.wordCountText,
                            color: .blue,
                            size: .small
                        )
                        TagView(
                            text: collection.level.displayName,
                            color: collection.level.color,
                            size: .small
                        )

                        Spacer()
                    }
                }
                
                // Add to dictionary button
                ActionButton(
                    "Add to My Dictionary",
                    systemImage: "plus.circle.fill",
                    style: .borderedProminent
                ) {
                    showAddToDictionary = true
                }
            }
        } trailingContent: {
            if collection.isPremium {
                Image(systemName: "crown.fill")
                    .foregroundColor(.yellow)
            }
        }
    }
    
    // MARK: - Words Section
    
    private var wordsSection: some View {
        CustomSectionView(
            header: "Contains:",
            headerFontStyle: .stealth,
            footer: "\(filteredWords.count) words",
            hPadding: .zero
        ) {
            if filteredWords.isEmpty {
                ContentUnavailableView(
                    "No words found",
                    systemImage: "magnifyingglass",
                    description: Text("Try adjusting your search terms.")
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
    
    // MARK: - Computed Properties
    
    private var filteredWords: [WordCollectionItem] {
        if searchText.isEmpty {
            return collection.words
        } else {
            return collection.words.filter { word in
                word.text.localizedCaseInsensitiveContains(searchText) ||
                word.definition.localizedCaseInsensitiveContains(searchText) ||
                word.examples.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }
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
                    partOfSpeech: "verb",
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
