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
                    ActionButton(Loc.addIdiom.localized(viewModel.searchText.trimmingCharacters(in: .whitespacesAndNewlines)), systemImage: "plus") {
                        viewModel.output.send(.showAddIdiom)
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
                                    Label(Loc.delete.localized, systemImage: "trash")
                                }
                            }
                        }
                    } else if viewModel.searchText.isNotEmpty {
                        ContentUnavailableView(
                            Loc.noIdiomsFound.localized,
                            systemImage: "magnifyingglass",
                            description: Text(Loc.addThisIdiom.localized)
                        )
                    } else {
                        ContentUnavailableView(
                            Loc.noIdiomsYet.localized,
                            systemImage: "quote.bubble",
                            description: Text(Loc.beginAddIdioms.localized)
                        )
                    }
                } trailingContent: {
                    HeaderButton(Loc.addIdiom.localized, icon: "plus", size: .small, style: .borderedProminent) {
                        viewModel.output.send(.showAddIdiom)
                    }
                }
            }
            .padding(.horizontal, 16)
        }
        .groupedBackground()
        .navigation(
            title: Loc.idioms.localized,
            mode: .large,
            trailingContent: {
                HeaderButtonMenu(icon: "ellipsis.circle") {
                    Picker(selection: _viewModel.projectedValue.sortingState) {
                        ForEach(SortingCase.idiomsSortingCases, id: \.self) { item in
                            Text(item.rawValue)
                                .tag(item)
                        }
                    } label: {
                        Text(Loc.sort.localized)
                    }
                    Picker(selection: _viewModel.projectedValue.filterState) {
                        ForEach(IdiomFilterCase.availableCases, id: \.self) { item in
                            Text(item.rawValue)
                                .tag(item)
                        }
                    } label: {
                        Text(Loc.filter.localized)
                    }
                }
            },
            bottomContent: {
                InputView.searchView(
                    Loc.searchIdioms.localized,
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
            return Loc.favorites.localized
        case .search:
            return Loc.found.localized
        default:
            return Loc.allIdioms.localized
        }
    }

    private var idiomsCount: String {
        return Loc.idiomsCount.localized(filteredIdioms.count)
    }
}
