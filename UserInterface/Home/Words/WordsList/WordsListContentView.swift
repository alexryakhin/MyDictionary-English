//
//  WordsListContentView.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import SwiftUI
import CoreUserInterface
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
        ScrollView {
            CustomSectionView(header: filterStateTitle, footer: viewModel.wordsCount) {
                if viewModel.wordsFiltered.isNotEmpty {
                    ListWithDivider(viewModel.wordsFiltered) { wordModel in
                        Button {
                            viewModel.handle(.showWordDetails(word: wordModel))
                        } label: {
                            WordListCellView(
                                model: .init(
                                    word: wordModel.word,
                                    isFavorite: wordModel.isFavorite,
                                    partOfSpeech: wordModel.partOfSpeech.rawValue
                                )
                            )
                            .padding(vertical: 12, horizontal: 16)
                            .background(Color.surface)
                            .contextMenu {
                                Button(role: .destructive) {
                                    viewModel.handle(.deleteWord(word: wordModel))
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .clippedWithBackground(.surface)
                }

                if viewModel.filterState == .search && viewModel.wordsFiltered.count < 10 {
                    Button {
                        addItem()
                    } label: {
                        Label("Add '\(viewModel.searchText.trimmingCharacters(in: .whitespacesAndNewlines))'", systemImage: "plus")
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .clippedWithPaddingAndBackground(.surface)
                    }
                }
            }
            .padding(vertical: 12, horizontal: 16)
        }
        .background(Color.background)
        .if(viewModel.words.isNotEmpty, transform: { view in
            view.searchable(text: $viewModel.searchText, placement: .navigationBarDrawer(displayMode: .always))
        })
        .toolbar {
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

    private var filterStateTitle: LocalizedStringKey {
        switch viewModel.filterState {
        case .none:
            return "All words"
        case .favorite:
            return "Favorites"
        case .search:
            return "Found"
        }
    }

    private var filterMenu: some View {
        Menu {
            Button {
                viewModel.handle(.selectFilterState(.none))
            } label: {
                Label("None", systemImage: viewModel.filterState == .none
                      ? "checkmark.circle.fill"
                      : "circle"
                )
            }
            Button {
                viewModel.handle(.selectFilterState(.favorite))
            } label: {
                Label("Favorites", systemImage: viewModel.filterState == .favorite
                      ? "checkmark.circle.fill"
                      : "circle"
                )
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
                viewModel.handle(.selectSortingState(.def))
            } label: {
                Label("Default", systemImage: viewModel.sortingState == .def
                      ? "checkmark.circle.fill"
                      : "circle"
                )
            }
            Button {
                viewModel.handle(.selectSortingState(.name))
            } label: {
                Label("Name", systemImage: viewModel.sortingState == .name
                      ? "checkmark.circle.fill"
                      : "circle"
                )
            }
            Button {
                viewModel.handle(.selectSortingState(.partOfSpeech))
            } label: {
                Label("Part of speech", systemImage: viewModel.sortingState == .partOfSpeech
                      ? "checkmark.circle.fill"
                      : "circle"
                )
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
