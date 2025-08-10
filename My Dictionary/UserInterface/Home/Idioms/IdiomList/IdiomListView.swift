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
        ScrollView {
            VStack(spacing: 16) {
                if viewModel.filterState == .search && filteredIdioms.count < 10 {
                    Button {
                        viewModel.output.send(.showAddIdiom)
                    } label: {
                        Label("Add '\(viewModel.searchText.trimmingCharacters(in: .whitespacesAndNewlines))'", systemImage: "plus")
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .clippedWithPaddingAndBackground()
                    }
                }

                CustomSectionView(
                    header: filterStateTitle,
                    footer: idiomsCount,
                    hPadding: .zero
                ) {
                    if filteredIdioms.isNotEmpty {
                        ListWithDivider(filteredIdioms) { idiomModel in
                            Button {
                                viewModel.output.send(.showIdiomDetails(idiomModel))
                            } label: {
                                IdiomListCellView(idiom: idiomModel)
                                    .id(idiomModel.id)
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                Button(role: .destructive) {
                                    viewModel.handle(.deleteIdiom(idiom: idiomModel))
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    } else if viewModel.searchText.isNotEmpty {
                        ContentUnavailableView(
                            "No idioms found",
                            systemImage: "magnifyingglass",
                            description: Text("Add this idiom by tapping on the button above")
                        )
                    } else {
                        ContentUnavailableView(
                            "No idioms yet",
                            systemImage: "quote.bubble",
                            description: Text("Begin to add idioms to your list by tapping on plus icon in upper left corner")
                        )
                    }
                } trailingContent: {
                    HeaderButton(text: "Add idiom", icon: "plus", style: .borderedProminent) {
                        viewModel.output.send(.showAddIdiom)
                    }
                }
            }
            .padding(.horizontal, 16)
        }
        .groupedBackground()
        .navigation(
            title: "Idioms",
            mode: .large,
            trailingContent: {
                HeaderButtonMenu(icon: "ellipsis.circle") {
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
