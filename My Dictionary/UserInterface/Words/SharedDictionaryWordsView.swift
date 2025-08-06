//
//  SharedDictionaryWordsView.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import SwiftUI

struct SharedDictionaryWordsView: View {
    @StateObject private var dictionaryService = DictionaryService.shared
    @State private var words: [Word] = []
    @State private var isLoading = true
    @State private var searchText = ""
    @State private var showingAddWord = false
    @State private var selectedWord: Word?
    
    let dictionary: DictionaryService.SharedDictionary
    
    var filteredWords: [Word] {
        if searchText.isEmpty {
            return words
        } else {
            return words.filter { word in
                word.wordItself.localizedCaseInsensitiveContains(searchText) ||
                word.definition.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Search Bar
            if !words.isEmpty {
                SearchBar(text: $searchText, placeholder: "Search words...")
                    .padding(.horizontal)
                    .padding(.vertical, 8)
            }

            // Words List
            if isLoading {
                ProgressView("Loading words...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if words.isEmpty {
                ContentUnavailableView {
                    Label("No words yet", systemImage: "textformat")
                } description: {
                    Text("Add words to this shared dictionary to get started")
                } actions: {
                    if dictionary.canEdit {
                        Button {
                            showingAddWord = true
                        } label: {
                            Label("Add Word", systemImage: "plus")
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            } else if filteredWords.isEmpty {
                ContentUnavailableView(
                    "No Results",
                    systemImage: "magnifyingglass",
                    description: Text("No words match your search")
                )
            } else {
                List {
                    ForEach(filteredWords) { word in
                        SharedDictionaryWordCell(word: word, dictionary: dictionary)
                            .onTapGesture {
                                selectedWord = word
                            }
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle(dictionary.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Back") {
                    // This will be handled by the navigation
                }
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                if dictionary.canEdit {
                    Button {
                        showingAddWord = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddWord) {
            AddWordContentView()
        }
        .sheet(item: $selectedWord) { word in
            SharedDictionaryWordDetailsView(word: word, dictionary: dictionary)
        }
        .onAppear {
            loadWords()
        }
    }
    
    private func loadWords() {
        isLoading = true
        
        // Add timeout to prevent infinite loading
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
            if self.isLoading {
                print("⏰ [SharedDictionaryWordsView] Loading timeout, stopping loader")
                self.isLoading = false
            }
        }
        
        dictionaryService.listenToSharedDictionaryWords(dictionaryId: dictionary.id) { words in
            DispatchQueue.main.async {
                self.words = words
                self.isLoading = false
            }
        }
    }
}

struct SharedDictionaryWordCell: View {
    let word: Word
    let dictionary: DictionaryService.SharedDictionary
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text(word.wordItself)
                    .bold()
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                if word.isFavorite {
                    Image(systemName: "heart.fill")
                        .font(.caption)
                        .foregroundColor(.accentColor)
                }
                
                Text(word.partOfSpeech)
                    .foregroundColor(.secondary)
                
                // Difficulty label
                if word.difficultyLevel > 0 {
                    Text(word.difficultyLabel)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(word.difficultyColor.opacity(0.2))
                        .foregroundColor(word.difficultyColor)
                        .clipShape(Capsule())
                }
                
                // Language label
                Text(word.languageCode.uppercased())
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.blue.opacity(0.2))
                    .foregroundColor(.blue)
                    .clipShape(Capsule())
                
                Image(systemName: "chevron.right")
                    .frame(sideLength: 12)
                    .foregroundColor(.secondary)
            }
            
            Text(word.definition)
                .font(.body)
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            // Tags
            if !word.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(word.tags, id: \.self) { tag in
                            Text(tag)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .clipShape(Capsule())
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Extensions

extension Word {
    var difficultyLabel: String {
        switch difficultyLevel {
        case 0: return "Easy"
        case 1: return "Medium"
        case 2: return "Hard"
        default: return "Easy"
        }
    }
    
    var difficultyColor: Color {
        switch difficultyLevel {
        case 0: return .green
        case 1: return .orange
        case 2: return .red
        default: return .green
        }
    }
}

struct SearchBar: View {
    @Binding var text: String
    let placeholder: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
            
            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
} 
