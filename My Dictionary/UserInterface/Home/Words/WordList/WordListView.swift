//
//  WordListView.swift
//  My Dictionary
//
//  Created by Alexander Riakhin on 8/9/25.
//

import SwiftUI
import StoreKit

struct WordListView: View {

    typealias ViewModel = WordListViewModel

    @AppStorage(UDKeys.isShowingRating) var isShowingRating: Bool = true
    @Environment(\.requestReview) var requestReview
    @ObservedObject var viewModel: ViewModel
    @StateObject private var dictionaryService = DictionaryService.shared

    init(viewModel: ViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        ScrollView {
            // MARK: - button to add a word from search input
            if viewModel.filterState == .search && viewModel.wordsFiltered.count < 10 {
                Button {
                    viewModel.output.send(.showAddWord)
                } label: {
                    Label(
                        "Add '\(viewModel.searchText.trimmingCharacters(in: .whitespacesAndNewlines))'",
                        systemImage: "plus"
                    )
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(6)
                }
                .buttonStyle(.bordered)
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .padding(.horizontal, 16)
            }

            CustomSectionView(
                header: viewModel.filterStateTitle,
                footer: viewModel.wordsCount,
                hPadding: 0
            ) {
                if viewModel.wordsFiltered.isNotEmpty {
                    ListWithDivider(viewModel.wordsFiltered) { wordModel in
                        Button {
                            viewModel.output.send(.showWordDetails(wordModel))
                        } label: {
                            WordListCellView(word: wordModel)
                                .id(wordModel.id)
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            if AuthenticationService.shared.isSignedIn {
                                Button {
                                    viewModel.output.send(.showAddExistingWordToShared(wordModel))
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
                    }
                } else {
                    ContentUnavailableView(
                        viewModel.filterState.emptyStateTitle,
                        systemImage: viewModel.filterState.emptyStateIcon,
                        description: Text(viewModel.filterState.emptyStateDescription)
                    )
                    .padding(.vertical, 24)
                }
            } trailingContent: {
                HeaderButton("Add Word", icon: "plus", style: .borderedProminent) {
                    AnalyticsService.shared.logEvent(.addWordTapped)
                    viewModel.output.send(.showAddWord)
                }
            }
            .padding(.horizontal, 16)
        }
        .animation(.default, value: viewModel.wordsFiltered)
        .animation(.default, value: viewModel.filterState)
        .animation(.default, value: viewModel.sortingState)
        .navigation(
            title: "Words",
            mode: .large,
            trailingContent: {
                HeaderButtonMenu(icon: "arrow.up.arrow.down") {
                    Picker("Sort", selection: _viewModel.projectedValue.sortingState) {
                        ForEach(SortingCase.allCases, id: \.self) { item in
                            Text(item.rawValue)
                                .tag(item)
                        }
                    }
                }

                if AuthenticationService.shared.isSignedIn {
                    HeaderButton(icon: "person.2") {
                        viewModel.output.send(.showSharedDictionaries)
                    }
                }
            },
            bottomContent: {
                VStack(spacing: 12) {
                    InputView.searchView(
                        "Search words...",
                        searchText: $viewModel.searchText
                    )
                    TagFilterView(viewModel: viewModel)
                }
            }
        )
        .onAppear {
            AnalyticsService.shared.logEvent(.wordsListOpened)
        }
    }
}
