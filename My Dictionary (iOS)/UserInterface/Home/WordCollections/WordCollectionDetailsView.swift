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
        .navigation(
            title: collection.title,
            mode: .large,
            trailingContent: {
                HeaderButton(
                    "Add All",
                    icon: "plus.circle.fill",
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
        CustomSectionView {
            VStack(alignment: .leading, spacing: 16) {
                // Collection info
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(collection.title)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Spacer()
                        
                        if collection.isPremium {
                            Image(systemName: "crown.fill")
                                .foregroundColor(.yellow)
                        }
                    }
                    
                    if let description = collection.description {
                        Text(description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text(collection.wordCountText)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(8)
                        
                        Text(collection.level.displayName)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(levelColor(for: collection.level).opacity(0.1))
                            .foregroundColor(levelColor(for: collection.level))
                            .cornerRadius(8)
                        
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
        }
    }
    
    // MARK: - Words Section
    
    private var wordsSection: some View {
        CustomSectionView(
            header: "Words",
            footer: "\(filteredWords.count) words"
        ) {
            if filteredWords.isEmpty {
                ContentUnavailableView(
                    "No words found",
                    systemImage: "magnifyingglass",
                    description: Text("Try adjusting your search terms.")
                )
                .padding(.vertical, 24)
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(filteredWords) { word in
                        WordCollectionItemRow(word: word) {
                            selectedWord = word
                        }
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

// MARK: - Word Collection Item Row

struct WordCollectionItemRow: View {
    let word: WordCollectionItem
    let onTap: VoidHandler
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(word.text)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if let phonetics = word.phonetics {
                        Text(phonetics)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Text(word.definition)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                    
                    if !word.examples.isEmpty {
                        Text(word.examples.first ?? "")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .italic()
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                VStack {
                    Text(word.partOfSpeech)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(4)
                    
                    Spacer()
                }
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Add Collection to Dictionary View

struct AddCollectionToDictionaryView: View {
    let collection: WordCollection
    @Environment(\.dismiss) private var dismiss
    @State private var selectedWords: Set<String> = []
    @State private var isAdding = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Add Words to Dictionary")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Select words from '\(collection.title)' to add to your personal dictionary.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                
                // Words list
                List {
                    ForEach(collection.words) { word in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(word.text)
                                    .font(.headline)
                                Text(word.definition)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(2)
                            }
                            
                            Spacer()
                            
                            Image(systemName: selectedWords.contains(word.id) ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(selectedWords.contains(word.id) ? .blue : .gray)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if selectedWords.contains(word.id) {
                                selectedWords.remove(word.id)
                            } else {
                                selectedWords.insert(word.id)
                            }
                        }
                    }
                }
                .listStyle(.plain)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add (\(selectedWords.count))") {
                        addSelectedWords()
                    }
                    .disabled(selectedWords.isEmpty || isAdding)
                }
            }
        }
    }
    
    private func addSelectedWords() {
        isAdding = true
        
        // TODO: Implement adding words to dictionary
        // This would convert WordCollectionItem to Word and save to Core Data
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            isAdding = false
            dismiss()
        }
    }
}

// MARK: - Word Collection Item Details View

struct WordCollectionItemDetailsView: View {
    let word: WordCollectionItem
    let collection: WordCollection
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Word header
                    VStack(alignment: .leading, spacing: 8) {
                        Text(word.text)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        if let phonetics = word.phonetics {
                            Text(phonetics)
                                .font(.title3)
                                .foregroundColor(.secondary)
                        }
                        
                        Text(word.partOfSpeech)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(8)
                    }
                    
                    // Definition
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Definition")
                            .font(.headline)
                        Text(word.definition)
                            .font(.body)
                    }
                    
                    // Examples
                    if !word.examples.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Examples")
                                .font(.headline)
                            
                            ForEach(word.examples, id: \.self) { example in
                                Text("• \(example)")
                                    .font(.body)
                                    .padding(.leading, 8)
                            }
                        }
                    }
                    
                    // Collection info
                    VStack(alignment: .leading, spacing: 8) {
                        Text("From Collection")
                            .font(.headline)
                        Text(collection.title)
                            .font(.body)
                            .foregroundColor(.blue)
                    }
                }
                .padding(16)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
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
