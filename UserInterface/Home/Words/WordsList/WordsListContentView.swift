//
//  WordsListContentView.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import SwiftUI
import StoreKit

struct WordsListContentView: View {

    typealias ViewModel = WordsListViewModel

    @AppStorage(UDKeys.isShowingRating) var isShowingRating: Bool = true
    @Environment(\.requestReview) var requestReview
    @ObservedObject var viewModel: ViewModel

    @State private var showingAddWord = false

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
                if viewModel.wordsFiltered.isNotEmpty {
                    Section {
                        ForEach(viewModel.wordsFiltered) { wordModel in
                            WordListCellView(word: wordModel)
                                .contextMenu {
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
                Button {
                    AnalyticsService.shared.logEvent(.addWordTapped)
                    showingAddWord = true
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
        .alert(isPresented: $viewModel.isShowingAlert) {
            Alert(
                title: Text(viewModel.alertModel.title),
                message: Text(viewModel.alertModel.message ?? ""),
                primaryButton: .default(Text(viewModel.alertModel.actionText ?? "OK")) {
                    viewModel.alertModel.action?()
                },
                secondaryButton: viewModel.alertModel.destructiveActionText != nil ? .destructive(Text(viewModel.alertModel.destructiveActionText!)) {
                    viewModel.alertModel.destructiveAction?()
                } : .cancel()
            )
        }
    }
}
