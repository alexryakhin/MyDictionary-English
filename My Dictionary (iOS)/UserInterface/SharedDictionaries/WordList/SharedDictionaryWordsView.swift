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
    @StateObject private var viewModel: SharedWordListViewModel

    @State private var showingAddWord = false
    @State var dictionary: SharedDictionary

    init(dictionary: SharedDictionary) {
        self.dictionary = dictionary
        self._viewModel = StateObject(wrappedValue: SharedWordListViewModel(dictionaryId: dictionary.id))
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                CustomSectionView(
                    header: Loc.Words.words,
                    footer: viewModel.wordsCount,
                    hPadding: .zero
                ) {
                    // Words List
                    if viewModel.wordsFiltered.isEmpty {
                        if viewModel.words.isEmpty {
                            ContentUnavailableView(
                                Loc.SharedDictionaries.noWordsYet,
                                systemImage: "textformat",
                                description: Text(Loc.SharedDictionaries.addWordsToSharedDictionary)
                            )
                        } else {
                            ContentUnavailableView(
                                Loc.SharedDictionaries.noResults,
                                systemImage: "magnifyingglass",
                                description: Text(Loc.SharedDictionaries.noWordsMatchFilter)
                            )
                        }
                    } else {
                        ListWithDivider(viewModel.wordsFiltered) { word in
                            SharedWordListCellView(word: word)
                                .id(word.id)
                                .onTap {
                                    navigationManager.navigationPath.append(NavigationDestination.sharedWordDetails(word, dictionaryId: dictionary.id))
                                }
                       }
                    }
                } trailingContent: {
                    if dictionary.canEdit {
                        HeaderButton(Loc.Words.addWord, icon: "plus", size: .small, style: .borderedProminent) {
                            showingAddWord = true
                        }
                    }
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
        .animation(.default, value: viewModel.filterState)
        .animation(.default, value: viewModel.sortingState)
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
                VStack(spacing: 12) {
                    InputView.searchView(Loc.Words.searchWords, searchText: $viewModel.searchText)
                    SharedWordListFilterView(viewModel: viewModel)
                }
            }
        )
        .sheet(isPresented: $showingAddWord) {
            AddWordView(
                input: viewModel.searchText,
                selectedDictionaryId: dictionary.id,
                isWord: true
            )
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
        // Force a refresh of the shared dictionary words
        dictionaryService.listenToSharedDictionaryWords(dictionaryId: dictionary.id)
        
        // Add a small delay to ensure the refresh completes
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
    }
}
