//
//  SharedDictionaryWordsView.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import SwiftUI

struct SharedDictionaryWordsView: View {
    @StateObject private var dictionaryService = DictionaryService.shared
    @StateObject private var navigationManager: NavigationManager = .shared

    @State private var searchText = ""
    @State private var showingAddWord = false
    @State var dictionary: SharedDictionary

    var filteredWords: [SharedWord] {
        let sharedWordsForDictionary = dictionaryService.sharedWords[dictionary.id] ?? []
        
        if searchText.isEmpty {
            return sharedWordsForDictionary
        } else {
            return sharedWordsForDictionary.filter { word in
                word.wordItself.localizedCaseInsensitiveContains(searchText) ||
                word.definition.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                CustomSectionView(
                    header: "Words",
                    footer: "\(filteredWords.count) words",
                    hPadding: .zero
                ) {
                    // Words List
                    if filteredWords.isEmpty {
                        ContentUnavailableView(
                            "No words yet",
                            systemImage: "textformat",
                            description: Text("Add words to this shared dictionary to get started")
                        )
                    } else if filteredWords.isEmpty {
                        ContentUnavailableView(
                            "No Results",
                            systemImage: "magnifyingglass",
                            description: Text("No words match your search")
                        )
                    } else {
                        ListWithDivider(filteredWords) { word in
                            SharedWordListCellView(word: word)
                                .id(word.id)
                                .onTap {
                                    navigationManager.navigationPath.append(NavigationDestination.sharedWordDetails(word, dictionaryId: dictionary.id))
                                }
                       }
                    }
                } trailingContent: {
                    if dictionary.canEdit {
                        HeaderButton("Add Word", icon: "plus", style: .borderedProminent) {
                            showingAddWord = true
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
        }
        .groupedBackground()
        .navigation(
            title: dictionary.name,
            mode: .inline,
            showsBackButton: true,
            trailingContent: {
                HeaderButton(icon: "info.circle") {
                    navigationManager.navigationPath.append(NavigationDestination.sharedDictionaryDetails(dictionary))
                }
            },
            bottomContent: {
                InputView.searchView("Search words", searchText: $searchText)
            }
        )
        .sheet(isPresented: $showingAddWord) {
            AddWordContentView(selectedDictionaryId: dictionary.id)
        }
        .onAppear {
            dictionaryService.listenToSharedDictionaryWords(dictionaryId: dictionary.id)
        }
        .refreshable {
            await refreshDictionaryWords()
        }
        .onChange(of: dictionaryService.sharedDictionaries) { newValue in
            if let dictionary = newValue.first(where: { $0.id == self.dictionary.id }) {
                self.dictionary = dictionary
                if !dictionary.canView {
                    NavigationManager.shared.popToRoot()
                }
            } else {
                NavigationManager.shared.popToRoot()
            }
        }
    }
    
    private func refreshDictionaryWords() async {
        print("🔄 [SharedDictionaryWordsView] Pull-to-refresh triggered for dictionary: \(dictionary.id)")
        
        // Force a refresh of the shared dictionary words
        dictionaryService.listenToSharedDictionaryWords(dictionaryId: dictionary.id)
        
        // Add a small delay to ensure the refresh completes
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        print("✅ [SharedDictionaryWordsView] Pull-to-refresh completed for dictionary: \(dictionary.id)")
    }
}
