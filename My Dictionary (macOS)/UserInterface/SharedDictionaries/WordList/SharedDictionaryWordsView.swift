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

    init(dictionary: SharedDictionary) {
        self.dictionary = dictionary
        self._viewModel = StateObject(wrappedValue: SharedWordListViewModel(dictionaryId: dictionary.id))
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                CustomSectionView(
                    header: "Words",
                    footer: "\(viewModel.wordsCount)",
                    hPadding: .zero
                ) {
                    // Words List
                    if viewModel.wordsFiltered.isEmpty {
                        if viewModel.words.isEmpty {
                            ContentUnavailableView(
                                "No words yet",
                                systemImage: "textformat",
                                description: Text("Add words to this shared dictionary to get started")
                            )
                        } else {
                            ContentUnavailableView(
                                "No Results",
                                systemImage: "magnifyingglass",
                                description: Text("No words match your current filter")
                            )
                        }
                    } else {
                        ListWithDivider(viewModel.wordsFiltered) { word in
                            SharedWordListCellView(word: word)
                                .id(word.id)
                                .onTap {
                                    sideBarManager.selectedSharedWord = word
                                }
                       }
                    }
                } trailingContent: {
                    if dictionary.canEdit {
                        HeaderButton("Add Word", icon: "plus", size: .small, style: .borderedProminent) {
                            showingAddWord = true
                        }
                    }
                }
            }
            .padding(12)
        }
        .groupedBackground()
        .navigationTitle(dictionary.name)
        .searchable(text: $viewModel.searchText, prompt: "Search words")
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                // Info button
                Button {
                    // TODO: show dictionary info in a window
                } label: {
                    Image(systemName: "info.circle")
                }
                .help("Dictionary Details")
                
                // Add word button
                if dictionary.canEdit {
                    Button {
                        showingAddWord = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .help("Add Word")
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            SharedWordListFilterView(viewModel: viewModel)
                .padding(.vertical, 8)
                .background(.regularMaterial)
        }
        .sheet(isPresented: $showingAddWord) {
            AddWordView(
                inputWord: viewModel.searchText,
                selectedDictionaryId: dictionary.id
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
                    dismiss()
                }
            } else {
                dismiss()
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
