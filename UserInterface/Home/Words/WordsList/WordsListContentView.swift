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
import struct Services.AnalyticsService

public struct WordsListContentView: PageView {

    public typealias ViewModel = WordsListViewModel

    @AppStorage(UDKeys.isShowingRating) var isShowingRating: Bool = true
    @AppStorage(UDKeys.isShowingOnboarding) var isShowingOnboarding: Bool = true
    @Environment(\.requestReview) var requestReview
    @ObservedObject public var viewModel: ViewModel

    public init(viewModel: ViewModel) {
        self._viewModel = ObservedObject(wrappedValue: viewModel)
    }

    public var contentView: some View {
        List {
            Section {
                ForEach(viewModel.wordsFiltered) { wordModel in
                    Button {
                        viewModel.handle(.showWordDetails(word: wordModel))
                        AnalyticsService.shared.logEvent(.wordOpened(word: wordModel.word))
                    } label: {
                        WordListCellView(
                            model: .init(
                                word: wordModel.word,
                                isFavorite: wordModel.isFavorite,
                                partOfSpeech: wordModel.partOfSpeech.rawValue
                            )
                        )
                    }
                }
                .onDelete {
                    viewModel.handle(.deleteWord($0))
                }

                if viewModel.filterState == .search && viewModel.wordsFiltered.count < 10 {
                    Button {
                        AnalyticsService.shared.logEvent(.addWordFromSearchTapped(word: viewModel.searchText))
                        addItem()
                    } label: {
                        Text("Add `\(viewModel.searchText.trimmingCharacters(in: .whitespacesAndNewlines))`")
                    }
                }
            } header: {
                if let title = viewModel.filterState.title {
                    Text(title)
                }
            } footer: {
                if !viewModel.wordsFiltered.isEmpty {
                    Text(viewModel.wordsCount)
                }
            }
        }
        .listStyle(.insetGrouped)
        .if(viewModel.words.isNotEmpty, transform: { view in
            view.searchable(text: $viewModel.searchText, placement: .navigationBarDrawer(displayMode: .always))
        })
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                EditButton()
            }
            ToolbarItem {
                Button {
                    AnalyticsService.shared.logEvent(.addWordTapped)
                    addItem()
                } label: {
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
        .onAppear {
            AnalyticsService.shared.logEvent(.wordsListOpened)
        }
        .sheet(isPresented: $isShowingOnboarding) {
            isShowingOnboarding = false
        } content: {
            OnboardingView()
        }
    }

    public func placeholderView(props: PageState.PlaceholderProps) -> some View {
        EmptyListView(
            label: "No words yet",
            description: "Begin to add words to your list by tapping on plus icon in upper left corner",
            background: .background
        ) {
            Button("Add your first word!", action: addItem)
                .buttonStyle(.borderedProminent)
        }
    }

    private func addItem() {
        if isShowingRating && viewModel.words.count > 15 {
            requestReview()
            isShowingRating = false
        }
        viewModel.handle(.showAddWord)
    }

    private var filterMenu: some View {
        Menu {
            Button {
                withAnimation {
                    viewModel.handle(.selectFilterState(.none))
                }
            } label: {
                if viewModel.filterState == .none {
                    Image(systemName: "checkmark")
                }
                Text("None")
            }
            Button {
                withAnimation {
                    viewModel.handle(.selectFilterState(.favorite))
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
                    viewModel.handle(.selectSortingState(.def))
                }
            } label: {
                if viewModel.sortingState == .def {
                    Image(systemName: "checkmark")
                }
                Text("Default")
            }
            Button {
                withAnimation {
                    viewModel.handle(.selectSortingState(.name))
                }
            } label: {
                if viewModel.sortingState == .name {
                    Image(systemName: "checkmark")
                }
                Text("Name")
            }
            Button {
                withAnimation {
                    viewModel.handle(.selectSortingState(.partOfSpeech))
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
