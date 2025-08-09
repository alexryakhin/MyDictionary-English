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
        List {
            // Shared Dictionaries Section
            if AuthenticationService.shared.isSignedIn && !dictionaryService.sharedDictionaries.isEmpty {
                Section("Shared Dictionaries") {
                    ForEach(dictionaryService.sharedDictionaries) { dictionary in
                        Button {
                            viewModel.output.send(.showSharedDictionary(dictionary))
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
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            if viewModel.wordsFiltered.isNotEmpty {
                Section {
                    ForEach(viewModel.wordsFiltered) { wordModel in
                        Button {
                            viewModel.output.send(.showWordDetails(wordModel))
                        } label: {
                            WordListCellView(word: wordModel)
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
                } header: {
                    Text(viewModel.filterStateTitle)
                } footer: {
                    Text(viewModel.wordsCount)
                }
            }

            if viewModel.filterState == .search && viewModel.wordsFiltered.count < 10 {
                Button {
                    viewModel.output.send(.showAddWord)
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
