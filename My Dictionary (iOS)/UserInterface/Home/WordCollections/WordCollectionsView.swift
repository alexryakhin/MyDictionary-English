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
    @State private var selectedLanguage: String = "en"
    @State private var selectedLevel: WordLevel?
    @State private var searchText = ""
    
    // MARK: - Body
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
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
            }
        }
        .navigation(
            title: "Word Catalog",
            mode: .large,
            trailingContent: {
                if !collectionsManager.isLoading {
                    HeaderButton(icon: "arrow.clockwise") {
                        Task {
                            await collectionsManager.fetchCollections()
                        }
                    }
                }
            },
            bottomContent: {
                VStack(spacing: 12) {
                    InputView.searchView(
                        "Search collections",
                        searchText: $searchText
                    )
                    filtersView
                }
            }
        )
        .onAppear {
            Task {
                await collectionsManager.fetchCollections()
            }
        }
        .onChange(of: searchText) {
            // Filter collections based on search text
        }
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Loading word collections...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, 60)
    }
    
    // MARK: - Collections Content
    
    private var collectionsContent: some View {
        LazyVStack(spacing: 20) {
            // Featured collections section
            if let featuredCollections = featuredCollections, !featuredCollections.isEmpty {
                featuredCollectionsSection(featuredCollections)
            }
            
            // Collections grouped by language
            ForEach(availableLanguages, id: \.self) { languageCode in
                let languageCollections = filteredCollections(for: languageCode)
                if !languageCollections.isEmpty {
                    languageSection(languageCode: languageCode, collections: languageCollections)
                }
            }
        }
    }
    
    // MARK: - Empty State View
    
    private var emptyStateView: some View {
        ContentUnavailableView(
            "No Collections Available",
            systemImage: "book.closed",
            description: Text("Word collections will appear here when they become available.")
        )
        .padding(.vertical, 60)
    }
    
    // MARK: - Filters View
    
    private var filtersView: some View {
        HStack(spacing: 12) {
            // Language picker
            Picker("Language", selection: $selectedLanguage) {
                ForEach(availableLanguages, id: \.self) { languageCode in
                    Text(WordCollectionKeys.allCases.first { $0.languageCode == languageCode }?.displayName ?? languageCode.uppercased())
                        .tag(languageCode)
                }
            }
            .pickerStyle(.menu)
            
            // Level picker
            Picker("Level", selection: $selectedLevel) {
                Text("All Levels")
                    .tag(nil as WordLevel?)
                ForEach(WordLevel.allCases, id: \.self) { level in
                    Text(level.displayName)
                        .tag(level as WordLevel?)
                }
            }
            .pickerStyle(.menu)
        }
    }
    
    // MARK: - Featured Collections Section
    
    private func featuredCollectionsSection(_ collections: [WordCollection]) -> some View {
        CustomSectionView(header: "Featured") {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(collections) { collection in
                        FeaturedCollectionCard(collection: collection)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }
    
    // MARK: - Language Section
    
    private func languageSection(languageCode: String, collections: [WordCollection]) -> some View {
        CustomSectionView(
            header: WordCollectionKeys.allCases.first { $0.languageCode == languageCode }?.displayName ?? languageCode.uppercased(),
            footer: "\(collections.count) collections"
        ) {
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(collections) { collection in
                    CollectionCard(collection: collection)
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var availableLanguages: [String] {
        let languages = Set(collectionsManager.collections.map { $0.languageCode })
        return Array(languages).sorted()
    }
    
    private var featuredCollections: [WordCollection]? {
        // Return collections marked as premium or with special titles
        let featured = collectionsManager.collections.filter { collection in
            collection.isPremium || 
            collection.title.lowercased().contains("gold") ||
            collection.title.lowercased().contains("essential") ||
            collection.title.lowercased().contains("top")
        }
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
        
        return collections
    }
}

// MARK: - Collection Card Components

struct CollectionCard: View {
    let collection: WordCollection
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Collection image placeholder
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.2))
                .frame(height: 80)
                .overlay(
                    Image(systemName: "book.closed.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(collection.title)
                    .font(.headline)
                    .lineLimit(2)
                
                Text(collection.wordCountText)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack {
                    Text(collection.level.displayName)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(levelColor(for: collection.level).opacity(0.2))
                        .foregroundColor(levelColor(for: collection.level))
                        .cornerRadius(4)
                    
                    Spacer()
                    
                    if collection.isPremium {
                        Image(systemName: "crown.fill")
                            .font(.caption2)
                            .foregroundColor(.yellow)
                    }
                }
            }
        }
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    private func levelColor(for level: WordLevel) -> Color {
        switch level {
        case .a1, .a2:
            return .green
        case .b1, .b2:
            return .orange
        case .c1, .c2:
            return .red
        }
    }
}

struct FeaturedCollectionCard: View {
    let collection: WordCollection
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Featured image
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        colors: [.blue.opacity(0.8), .purple.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 200, height: 120)
                .overlay(
                    VStack {
                        Image(systemName: "star.fill")
                            .font(.title)
                            .foregroundColor(.white)
                        Text(collection.title)
                            .font(.headline)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                    }
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(collection.title)
                    .font(.headline)
                    .lineLimit(2)
                
                if let description = collection.description {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(3)
                }
                
                Text(collection.wordCountText)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(width: 200, alignment: .leading)
        }
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

#Preview {
    NavigationStack {
        WordCollectionsView()
    }
}
