//
//  SharedDictionaryWordsView.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import SwiftUI

struct SharedDictionaryWordsView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var dictionaryService = DictionaryService.shared
    @StateObject private var viewModel: SharedWordListViewModel
    @StateObject private var sideBarManager = SideBarManager.shared

    @State private var dictionary: SharedDictionary
    @State private var showingAddWord = false
    @State private var showingDictionaryDetails = false

    init(dictionary: SharedDictionary) {
        self._dictionary = State(initialValue: dictionary)
        self._viewModel = StateObject(wrappedValue: SharedWordListViewModel(dictionaryId: dictionary.id))
    }
    
    var body: some View {
        ScrollViewWithCustomNavBar {
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
                        ListWithDivider(
                            viewModel.wordsFiltered,
                            dividerLeadingPadding: .zero,
                            dividerTrailingPadding: .zero
                        ) { word in
                            SharedWordListCellView(word: word)
                                .id(word.id)
                                .onTap {
                                    sideBarManager.selectedSharedWord = word
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
            .padding(12)
        } navigationBar: {
            SharedWordListFilterView(viewModel: viewModel)
                .padding(.vertical, 12)
        }
        .groupedBackground()
        .animation(.default, value: viewModel.filterState)
        .animation(.default, value: viewModel.sortingState)
        .navigationTitle(dictionary.name)
        .searchable(text: $viewModel.searchText, prompt: Loc.Words.searchWords)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                // Info button
                Button {
                    showingDictionaryDetails = true
                } label: {
                    Image(systemName: "info.circle")
                }
                .help(Loc.SharedDictionaries.dictionaryDetails)
                
                // Add word button
                if dictionary.canEdit {
                    Button {
                        showingAddWord = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .help(Loc.Words.addWord)
                }
            }
        }
        .sheet(isPresented: $showingAddWord) {
            AddWordView(
                input: viewModel.searchText,
                selectedDictionaryId: dictionary.id,
                isWord: true
            )
        }
        .sheet(isPresented: $showingDictionaryDetails) {
            SharedDictionaryDetailsView(dictionary: dictionary)
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
                    dismiss()
                }
            } else {
                dismiss()
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
