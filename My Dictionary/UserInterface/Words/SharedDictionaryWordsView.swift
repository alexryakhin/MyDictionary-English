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

    @Binding var navigationPath: NavigationPath
    @State var dictionary: SharedDictionary

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
                           Button {
                               let config = WordDetailsContentView.Config(
                                    word: word,
                                    dictionary: dictionary
                               )
                               navigationPath.append(NavigationDestination.wordDetails(config))
                           } label: {
                               WordListCellView(word: word)
                           }
                           .buttonStyle(.plain)
                       }
                    }
                } trailingContent: {
                    if dictionary.canEdit {
                        HeaderButton(text: "Add Word", icon: "plus", style: .borderedProminent) {
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
                Button {
                    navigationPath.append(NavigationDestination.sharedDictionaryDetails(dictionary))
                } label: {
                    Image(systemName: "info.circle")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                }
                .buttonStyle(.bordered)
                .clipShape(Capsule())
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
        .onChange(of: dictionaryService.sharedDictionaries) { newValue in
            if let dictionary = newValue.first(where: { $0.id == self.dictionary.id }) {
                self.dictionary = dictionary
                if !dictionary.canView {
                    TabManager.shared.popToRootPublisher.send()
                }
            } else {
                TabManager.shared.popToRootPublisher.send()
            }
        }
    }
}
