//
//  IdiomListView.swift
//  My Dictionary
//
//  Created by Alexander Riakhin on 8/9/25.
//

import SwiftUI

struct IdiomListView: View {

    typealias ViewModel = IdiomListViewModel

    @ObservedObject var viewModel: ViewModel

    init(viewModel: ViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        List {
            if filteredIdioms.isNotEmpty {
                Section {
                    ForEach(filteredIdioms) { idiomModel in
                        Button {
                            viewModel.output.send(.showIdiomDetails(idiomModel))
                        } label: {
                            IdiomListCellView(idiom: idiomModel)
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button(role: .destructive) {
                                viewModel.handle(.deleteIdiom(idiom: idiomModel))
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        .tag(idiomModel)
                    }
                } header: {
                    Text(filterStateTitle)
                } footer: {
                    Text(idiomsCount)
                }
            }

            if viewModel.filterState == .search && filteredIdioms.count < 10 {
                Button {
                    viewModel.output.send(.showAddIdiom)
                } label: {
                    Label("Add '\(viewModel.searchText.trimmingCharacters(in: .whitespacesAndNewlines))'", systemImage: "plus")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .clippedWithPaddingAndBackground()
                }
            }
        }
        .groupedBackground()
        .overlay {
            if !filteredIdioms.isNotEmpty {
                ContentUnavailableView(
                    "No idioms yet",
                    systemImage: "quote.bubble",
                    description: Text("Begin to add idioms to your list by tapping on plus icon in upper left corner")
                )
                .groupedBackground()
            }
        }
        .navigation(
            title: "Idioms",
            mode: .large,
            trailingContent: {
                HStack {
                    Menu {
                        Picker(selection: _viewModel.projectedValue.sortingState) {
                            ForEach(SortingCase.idiomsSortingCases, id: \.self) { item in
                                Text(item.rawValue)
                                    .tag(item)
                            }
                        } label: {
                            Text("Sort")
                        }
                        Picker(selection: _viewModel.projectedValue.filterState) {
                            ForEach(IdiomFilterCase.availableCases, id: \.self) { item in
                                Text(item.rawValue)
                                    .tag(item)
                            }
                        } label: {
                            Text("Filter")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 16, height: 16)
                    }
                    .buttonStyle(.bordered)
                    .clipShape(Capsule())
                    
                    Button {
                        viewModel.output.send(.showAddIdiom)
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
                InputView.searchView(
                    "Search idioms...",
                    searchText: $viewModel.searchText
                )
            }
        )
        .onAppear {
            AnalyticsService.shared.logEvent(.idiomsListOpened)
        }
    }

    private var filteredIdioms: [CDIdiom] {
        switch viewModel.filterState {
        case .favorite:
            return viewModel.favoriteIdioms
        case .search:
            return viewModel.searchResults
        default:
            return viewModel.idioms
        }
    }

    private var filterStateTitle: String {
        switch viewModel.filterState {
        case .favorite:
            return "Favorites"
        case .search:
            return "Found"
        default:
            return "All idioms"
        }
    }

    private var idiomsCount: String {
        if filteredIdioms.count == 1 {
            return "1 idiom"
        } else {
            return "\(filteredIdioms.count) idioms"
        }
    }
}
