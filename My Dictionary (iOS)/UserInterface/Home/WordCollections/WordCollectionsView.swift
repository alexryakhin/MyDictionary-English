//
//  WordCollectionsView.swift
//  My Dictionary
//
//  Created by AI Assistant on 1/27/25.
//

import SwiftUI

struct WordCollectionsView: View {
    
    // MARK: - Properties
    
    @StateObject private var collectionsManager = WordCollectionsManager.shared
    @State private var selectedLanguage: String = "all"
    @State private var selectedLevel: WordLevel?
    @State private var searchText = ""
    @State private var showingPaywall = false
    
    // MARK: - Body
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if collectionsManager.isLoading {
                    loadingView
                } else if collectionsManager.hasCollections {
                    collectionsContent
                } else {
                    emptyStateView
                }
            }
            .padding(.horizontal, 16)
            .if(isPad) { view in
                view
                    .frame(maxWidth: 550, alignment: .center)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .groupedBackground()
        .navigation(
            title: Loc.WordCollections.wordCatalog,
            mode: .inline,
            showsBackButton: true,
            trailingContent: {
                if !collectionsManager.isLoading {
                    AsyncHeaderButton(icon: "arrow.clockwise") {
                        await collectionsManager.forceRefresh()
                    }
                }
            },
            bottomContent: {
                VStack(spacing: 12) {
                    InputView.searchView(
                        Loc.WordCollections.searchCollections,
                        searchText: $searchText
                    )
                    filtersView
                }
            }
        )
        .onChange(of: searchText) {
            // Filter collections based on search text
        }
        .withPaywall()
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            Text(Loc.WordCollections.loadingWordCollections)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, 60)
    }
    
    // MARK: - Collections Content
    
    private var collectionsContent: some View {
        LazyVStack(spacing: 20) {
            // Featured collections section (only show if "All Languages" is selected or for specific language)
            if selectedLanguage == "all" {
                if let featuredCollections = featuredCollections, !featuredCollections.isEmpty {
                    featuredCollectionsSection(featuredCollections)
                }
            } else {
                if let featuredCollections = featuredCollectionsForSelectedLanguage, !featuredCollections.isEmpty {
                    featuredCollectionsSection(featuredCollections)
                }
            }
            
            // Show collections based on selected language
            if selectedLanguage == "all" {
                // Show all languages grouped
                ForEach(availableLanguages, id: \.self) { languageCode in
                    languageSection(
                        languageCode: languageCode,
                        collections: filteredCollections(for: languageCode)
                    )
                }
            } else {
                // Show only selected language
                let selectedLanguageCollections = filteredCollections(for: selectedLanguage)
                if !selectedLanguageCollections.isEmpty {
                    selectedLanguageSection(collections: selectedLanguageCollections)
                } else {
                    emptyStateView
                }
            }
        }
    }
    
    // MARK: - Empty State View
    
    private var emptyStateView: some View {
        ContentUnavailableView(
            Loc.WordCollections.noCollectionsAvailable,
            systemImage: "book.closed",
            description: Text(Loc.WordCollections.noCollectionsAvailableDescription)
        )
        .padding(.vertical, 60)
    }
    
    // MARK: - Filters View
    
    private var filtersView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // Language picker
                var languageMenuTitle: String {
                    selectedLanguage == "all"
                    ? Loc.WordCollections.allLanguages
                    : WordCollectionKeys.allCases.first { $0.languageCode == selectedLanguage }?.displayName ?? selectedLanguage.uppercased()
                }
                HeaderButtonMenu(languageMenuTitle, icon: "chevron.down", size: .small) {
                    Picker(Loc.WordCollections.language, selection: $selectedLanguage) {
                        Text(Loc.WordCollections.allLanguages)
                            .tag("all")
                        ForEach(availableLanguages, id: \.self) { languageCode in
                            Text(WordCollectionKeys.allCases.first { $0.languageCode == languageCode }?.displayName ?? languageCode.uppercased())
                                .tag(languageCode)
                        }
                    }
                    .pickerStyle(.inline)
                }

                // Level picker
                var levelMenuTitle: String {
                    selectedLevel?.displayName ?? Loc.WordCollections.allLevels
                }
                HeaderButtonMenu(levelMenuTitle, icon: "chevron.down", size: .small) {
                    Picker(Loc.WordCollections.level, selection: $selectedLevel) {
                        Text(Loc.WordCollections.allLevels)
                            .tag(nil as WordLevel?)
                        ForEach(WordLevel.allCases, id: \.self) { level in
                            Text(level.displayName)
                                .tag(level as WordLevel?)
                        }
                    }
                    .pickerStyle(.inline)
                }
            }
        }
    }
    
    // MARK: - Featured Collections Section
    
    private func featuredCollectionsSection(_ collections: [WordCollection]) -> some View {
        CustomSectionView(header: Loc.WordCollections.featured) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(collections) { collection in
                        WordCollectionPreviewCard(collection: collection)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.viewAligned)
            .scrollClipDisabled()
        }
    }
    
    // MARK: - Language Section
    
    private func languageSection(languageCode: String, collections: [WordCollection]) -> some View {
        CustomSectionView(
            header: WordCollectionKeys.allCases.first { $0.languageCode == languageCode }?.displayName ?? languageCode.uppercased(),
            footer: Loc.Plurals.WordCollections.collectionsCount(collections.count)
        ) {
            if collections.isNotEmpty {
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ], spacing: 12) {
                    ForEach(collections) { collection in
                        WordCollectionGridPreviewCard(collection: collection)
                    }
                }
                .padding(.bottom, 12)
            } else {
                ContentUnavailableView(
                    Loc.WordCollections.noCollectionsAvailable,
                    systemImage: "book.closed",
                    description: Text(Loc.WordCollections.noCollectionsAvailableDescription)
                )
            }
        }
    }
    
    // MARK: - Selected Language Section
    
    private func selectedLanguageSection(collections: [WordCollection]) -> some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ], spacing: 12) {
            ForEach(collections) { collection in
                WordCollectionGridPreviewCard(collection: collection)
            }
        }
        .padding(.bottom, 12)
    }
    
    // MARK: - Computed Properties
    
    private var availableLanguages: [String] {
        let languages = Set(collectionsManager.collections.map { $0.languageCode })
        return Array(languages).sorted()
    }
    
    private var featuredCollections: [WordCollection]? {
        // Return collections marked as featured using the new isFeatured flag
        let featured = collectionsManager.featuredCollections()
        return featured.isEmpty ? nil : Array(featured.prefix(10))
    }
    
    private var featuredCollectionsForSelectedLanguage: [WordCollection]? {
        // Return featured collections for the selected language
        let featured = collectionsManager.featuredCollections(for: selectedLanguage)
        return featured.isEmpty ? nil : Array(featured.prefix(3))
    }
    
    private func filteredCollections(for languageCode: String) -> [WordCollection] {
        var collections = collectionsManager.collections.filter { $0.languageCode == languageCode }
        
        // Filter by level if selected
        if let selectedLevel = selectedLevel {
            collections = collections.filter { $0.level == selectedLevel }
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            collections = collections.filter { collection in
                collection.title.localizedCaseInsensitiveContains(searchText) ||
                collection.description?.localizedCaseInsensitiveContains(searchText) == true ||
                collection.words.contains { $0.text.localizedCaseInsensitiveContains(searchText) }
            }
        }
        
        // Sort collections: by level, then by title
        return collections.sorted { collection1, collection2 in
            // Sort by level (A1, A2, B1, B2, C1, C2)
            if collection1.level != collection2.level {
                return collection1.level.rawValue < collection2.level.rawValue
            }
            
            // Sort by title alphabetically
            return collection1.title.localizedCaseInsensitiveCompare(collection2.title) == .orderedAscending
        }
    }
}

#Preview {
    NavigationStack {
        WordCollectionsView()
    }
}
