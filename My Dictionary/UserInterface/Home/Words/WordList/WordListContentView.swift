//
//  WordListContentView.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import SwiftUI
import StoreKit

struct WordListContentView: View {

    typealias ViewModel = WordListViewModel

    @AppStorage(UDKeys.isShowingRating) var isShowingRating: Bool = true
    @Environment(\.requestReview) var requestReview
    @ObservedObject var viewModel: ViewModel

    @State private var showingAddWord = false
    @State private var showingAddSharedDictionary = false
    @State private var showingAddExistingWordToShared = false
    @State private var selectedWordForShared: CDWord?
    @StateObject private var dictionaryService = DictionaryService.shared

    init(viewModel: ViewModel) {
        self._viewModel = ObservedObject(wrappedValue: viewModel)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Tag Filter Section
            if viewModel.words.isNotEmpty {
                TagFilterView(viewModel: viewModel)
                    .padding(.vertical, 8)
            }
            
            // Words List
            List(selection: $viewModel.selectedWord) {
                // Shared Dictionaries Section
                if AuthenticationService.shared.isSignedIn && !dictionaryService.sharedDictionaries.isEmpty {
                    Section("Shared Dictionaries") {
                        ForEach(dictionaryService.sharedDictionaries) { dictionary in
                            NavigationLink {
                                SharedDictionaryWordsView(dictionary: dictionary)
                            } label: {
                                HStack {
                                    Image(systemName: "person.2")
                                        .foregroundColor(.blue)
                                    VStack(alignment: .leading) {
                                        Text(dictionary.name)
                                            .font(.headline)
                                        Text("\(dictionary.collaborators.count) collaborators")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                    }
                }
                if viewModel.wordsFiltered.isNotEmpty {
                    Section {
                        ForEach(viewModel.wordsFiltered) { wordModel in
                            WordListCellView(word: wordModel)
                                .contextMenu {
                                    if AuthenticationService.shared.isSignedIn {
                                        Button {
                                            selectedWordForShared = wordModel
                                        } label: {
                                            Label("Add to Shared Dictionary", systemImage: "person.2")
                                        }
                                    }
                                    
                                    Button(role: .destructive) {
                                        viewModel.handle(.deleteWord(word: wordModel))
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                                .tag(wordModel)
                        }
                    } header: {
                        Text(viewModel.filterStateTitle)
                    } footer: {
                        Text(viewModel.wordsCount)
                    }
                }

                if viewModel.filterState == .search && viewModel.wordsFiltered.count < 10 {
                    Button {
                        showingAddWord.toggle()
                    } label: {
                        Label("Add '\(viewModel.searchText.trimmingCharacters(in: .whitespacesAndNewlines))'", systemImage: "plus")
                    }
                }
            }
            .overlay {
                if !viewModel.wordsFiltered.isNotEmpty {
                    ContentUnavailableView(
                        viewModel.filterState.emptyStateTitle,
                        systemImage: viewModel.filterState.emptyStateIcon,
                        description: Text(viewModel.filterState.emptyStateDescription)
                    )
                }
            }
        }
        .navigationTitle("Words")
        .if(viewModel.words.isNotEmpty, transform: { view in
            view.searchable(text: $viewModel.searchText, placement: .navigationBarDrawer(displayMode: .always))
        })
        .toolbar {
            ToolbarItem {
                Menu {
                    Button {
                        AnalyticsService.shared.logEvent(.addWordTapped)
                        showingAddWord = true
                    } label: {
                        Label("Add Word", systemImage: "plus")
                    }
                    
                    if AuthenticationService.shared.isSignedIn {
                        Button {
                            showingAddSharedDictionary = true
                        } label: {
                            Label("Create Shared Dictionary", systemImage: "person.2")
                        }
                    }
                } label: {
                    Label("Add Item", systemImage: "plus")
                }
            }
            ToolbarItem(placement: .navigationBarLeading) {
                Menu {
                    Picker("Sort", selection: _viewModel.projectedValue.sortingState) {
                        ForEach(SortingCase.allCases, id: \.self) { item in
                            Text(item.rawValue)
                                .tag(item)
                        }
                    }
                } label: {
                    Image(systemName: "arrow.up.arrow.down")
                }
            }
        }
        .onAppear {
            AnalyticsService.shared.logEvent(.wordsListOpened)
        }
        .sheet(isPresented: $showingAddWord) {
            AddWordContentView()
        }
        .sheet(isPresented: $showingAddSharedDictionary) {
            AddSharedDictionaryView()
        }
        .sheet(item: $selectedWordForShared) { word in
            AddExistingWordToSharedView(word: word)
        }
    }
}
