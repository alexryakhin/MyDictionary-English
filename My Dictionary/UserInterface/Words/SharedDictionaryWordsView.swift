//
//  SharedDictionaryWordsView.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import SwiftUI

struct SharedDictionaryWordsView: View {
    @StateObject private var dictionaryService = DictionaryService.shared
    @StateObject private var wordsProvider = WordsProvider.shared
    @State private var searchText = ""
    @State private var showingAddWord = false

    let dictionary: DictionaryService.SharedDictionary
    
    var filteredWords: [CDWord] {
        let sharedWordsForDictionary = wordsProvider.sharedWords.filter { $0.sharedDictionaryId == dictionary.id }
        
        if searchText.isEmpty {
            return sharedWordsForDictionary
        } else {
            return sharedWordsForDictionary.filter { word in
                word.wordItself?.localizedCaseInsensitiveContains(searchText) ?? false ||
                word.definition?.localizedCaseInsensitiveContains(searchText) ?? false
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Search Bar
            if !filteredWords.isEmpty {
                SearchBar(text: $searchText, placeholder: "Search words...")
                    .padding(.horizontal)
                    .padding(.vertical, 8)
            }

            // Words List
            if filteredWords.isEmpty {
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
                        NavigationLink {
                            WordDetailsContentView(word: word, dictionary: dictionary)
                        } label: {
                            SharedDictionaryWordCell(word: word, dictionary: dictionary)
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle(dictionary.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                NavigationLink {
                    SharedDictionaryDetailsView(dictionary: dictionary)
                } label: {
                    Image(systemName: "info.circle")
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
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
            AddWordContentView(selectedDictionaryId: dictionary.id)
        }
        .onAppear {
            dictionaryService.listenToSharedDictionaryWords(dictionaryId: dictionary.id)
        }
    }
}

struct SharedDictionaryWordCell: View {
    @StateObject private var word: CDWord
    private let dictionary: DictionaryService.SharedDictionary

    init(word: CDWord, dictionary: DictionaryService.SharedDictionary) {
        self._word = StateObject(wrappedValue: word)
        self.dictionary = dictionary
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text(word.wordItself ?? "")
                    .bold()
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                if word.isFavorite {
                    Image(systemName: "heart.fill")
                        .font(.caption)
                        .foregroundColor(.accentColor)
                }
                
                Text(word.partOfSpeech ?? "")
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
                Text((word.languageCode ?? "en").uppercased())
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
            
            Text(word.definition ?? "")
                .font(.body)
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            // Tags
            if !word.tagsArray.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(word.tagsArray, id: \.id) { tag in
                            Text(tag.name ?? "")
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
