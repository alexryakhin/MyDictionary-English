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
            // Shared Dictionaries Section
            if AuthenticationService.shared.isSignedIn && !dictionaryService.sharedDictionaries.isEmpty {
                CustomSectionView(header: "Shared Dictionaries") {
                    ListWithDivider(dictionaryService.sharedDictionaries, dividerLeadingPadding: .zero) { dictionary in
                        Button {
                            viewModel.output.send(.showSharedDictionary(dictionary))
                        } label: {
                            HStack {
                                Image(systemName: "person.2")
                                    .foregroundStyle(.accent)
                                VStack(alignment: .leading) {
                                    Text(dictionary.name)
                                        .font(.headline)
                                    Text("\(dictionary.collaborators.count) collaborators")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
            }

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
                            if AuthenticationService.shared.isSignedIn && !wordModel.isSharedWord {
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
                HeaderButton(text: "Add Word", icon: "plus") {
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
                HStack {
                    Menu {
                        Picker("Sort", selection: _viewModel.projectedValue.sortingState) {
                            ForEach(SortingCase.allCases, id: \.self) { item in
                                Text(item.rawValue)
                                    .tag(item)
                            }
                        }
                    } label: {
                        Image(systemName: "arrow.up.arrow.down")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 16, height: 16)
                    }
                    .buttonStyle(.bordered)
                    .clipShape(Capsule())

                    Menu {
                        Button {
                            AnalyticsService.shared.logEvent(.addWordTapped)
                            viewModel.output.send(.showAddWord)
                        } label: {
                            Label("Add Word", systemImage: "plus")
                        }

                        if AuthenticationService.shared.isSignedIn {
                            Button {
                                viewModel.output.send(.showAddSharedDictionary)
                            } label: {
                                Label("Create Shared Dictionary", systemImage: "person.2")
                            }
                        }
                    } label: {
                        Image(systemName: "plus")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 16, height: 16)
                    }
                    .buttonStyle(.borderedProminent)
                    .clipShape(Capsule())
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
