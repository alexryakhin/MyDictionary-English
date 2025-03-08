//
//  WordsListContentView.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import SwiftUI
import CoreUserInterface
import CoreNavigation
import Core
import StoreKit

public struct WordsListContentView: PageView {

    @AppStorage(UDKeys.isShowingRating) var isShowingRating: Bool = true
    @ObservedObject public var viewModel: WordsListViewModel

    public init(viewModel: WordsListViewModel) {
        self._viewModel = ObservedObject(wrappedValue: viewModel)
    }

    public var contentView: some View {
        if viewModel.words.isNotEmpty {
            List {
                Section {
                    ForEach(viewModel.wordsFiltered) { word in
                        WordListCellView(model: .init(
                            word: word.word,
                            isFavorite: word.isFavorite,
                            partOfSpeech: word.partOfSpeech)
                        )
                    }
                    .onDelete(perform: viewModel.deleteWord)
                } header: {
                    if let title = viewModel.filterState.title {
                        Text(title)
                    }
                } footer: {
                    if !viewModel.wordsFiltered.isEmpty {
                        Text(viewModel.wordsCount)
                    }
                }

                if viewModel.filterState == .search && viewModel.wordsFiltered.count < 10 {
                    Button {
                        addItem()
                    } label: {
                        Text("Add '\(viewModel.searchText.trimmingCharacters(in: .whitespacesAndNewlines))'")
                    }
                }
            }
            .listStyle(.insetGrouped)
            .if(viewModel.words.isNotEmpty, transform: { view in
                view.searchable(text: $viewModel.searchText, placement: .navigationBarDrawer(displayMode: .always))
            })
            .navigationTitle("Words")
            .toolbar {
                if viewModel.words.isNotEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        EditButton()
                    }
                }
                ToolbarItem {
                    Button(action: addItem) {
                        Label("Add Item", systemImage: "plus")
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        filterMenu
                        sortMenu
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        } else {
            EmptyListView(
                label: "No words yet",
                description: "Begin to add words to your list by tapping on plus icon in upper left corner"
            ) {
                Button("Add your first word!", action: addItem)
                    .buttonStyle(.borderedProminent)
            }
        }
    }

    private func addItem() {
        if isShowingRating && viewModel.words.count > 15 {
            SKStoreReviewController.requestReview()
            isShowingRating = false
        }
    }

    private var filterMenu: some View {
        Menu {
            Button {
                withAnimation {
                    viewModel.filterState = .none
                }
            } label: {
                if viewModel.filterState == .none {
                    Image(systemName: "checkmark")
                }
                Text("None")
            }
            Button {
                withAnimation {
                    viewModel.filterState = .favorite
                }
            } label: {
                if viewModel.filterState == .favorite {
                    Image(systemName: "checkmark")
                }
                Text("Favorites")
            }
        } label: {
            Label {
                Text("Filter By")
            } icon: {
                Image(systemName: "paperclip")
            }
        }
    }

    private var sortMenu: some View {
        Menu {
            Button {
                withAnimation {
                    viewModel.selectSortingState(.def)
                }
            } label: {
                if viewModel.sortingState == .def {
                    Image(systemName: "checkmark")
                }
                Text("Default")
            }
            Button {
                withAnimation {
                    viewModel.selectSortingState(.name)
                }
            } label: {
                if viewModel.sortingState == .name {
                    Image(systemName: "checkmark")
                }
                Text("Name")
            }
            Button {
                withAnimation {
                    viewModel.selectSortingState(.partOfSpeech)
                }
            } label: {
                if viewModel.sortingState == .partOfSpeech {
                    Image(systemName: "checkmark")
                }
                Text("Part of speech")
            }

        } label: {
            Label {
                Text("Sort By")
            } icon: {
                Image(systemName: "arrow.up.arrow.down")
            }
        }
    }
}
