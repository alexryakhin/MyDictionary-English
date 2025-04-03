//
//  IdiomsListContentView.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import SwiftUI
import CoreUserInterface
import Core
import Services

public struct IdiomsListContentView: PageView {

    public typealias ViewModel = IdiomsListViewModel

    @ObservedObject public var viewModel: ViewModel

    public init(viewModel: ViewModel) {
        self.viewModel = viewModel
    }

    public var contentView: some View {
        ScrollView {
            CustomSectionView(header: filterStateTitle, footer: idiomsCount) {
                if filteredIdioms.isNotEmpty {
                    ListWithDivider(filteredIdioms) { idiomModel in
                        Button {
                            viewModel.handle(.showIdiomDetails(idiom: idiomModel))
                        } label: {
                            IdiomListCellView(
                                model: .init(
                                    idiom: idiomModel.idiom,
                                    isFavorite: idiomModel.isFavorite
                                )
                            )
                            .padding(vertical: 12, horizontal: 16)
                            .background(Color.surface)
                            .contextMenu {
                                Button(role: .destructive) {
                                    viewModel.handle(.deleteIdiom(idiom: idiomModel))
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .clippedWithBackground(.surface)
                }

                if viewModel.filterState == .search && filteredIdioms.count < 10 {
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
        .animation(.default, value: viewModel.sortingState)
        .animation(.default, value: viewModel.filterState)
        .animation(.default, value: viewModel.idioms)
        .background(Color.background)
        .if(viewModel.idioms.isNotEmpty, transform: { view in
            view.searchable(text: $viewModel.searchText, placement: .navigationBarDrawer(displayMode: .always))
        })
        .toolbar {
            ToolbarItem {
                Button(action: addItem) {
                    Label("Add Item", systemImage: "plus")
                }
            }
            ToolbarItem(placement: .navigationBarLeading) {
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
                        ForEach(FilterCase.availableCases, id: \.self) { item in
                            Text(item.rawValue)
                                .tag(item)
                        }
                    } label: {
                        Text("Filter")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .onAppear {
            AnalyticsService.shared.logEvent(.idiomsListOpened)
        }
    }

    public func placeholderView(props: PageState.PlaceholderProps) -> some View {
        EmptyListView(
            label: "No idioms yet!",
            description: "Begin to add idioms to your list by tapping on plus icon in upper left corner",
            background: .background
        )
    }

    private func addItem() {
        viewModel.handle(.showAddIdiom)
    }

    private var filteredIdioms: [Idiom] {
        switch viewModel.filterState {
        case .none:
            return viewModel.idioms
        case .favorite:
            return viewModel.favoriteIdioms
        case .search:
            return viewModel.searchResults
        }
    }

    private var filterStateTitle: LocalizedStringKey {
        switch viewModel.filterState {
        case .none:
            return "All idioms"
        case .favorite:
            return "Favorites"
        case .search:
            return "Found"
        }
    }

    private var idiomsCount: LocalizedStringKey? {
        guard filteredIdioms.isNotEmpty else {
            return nil
        }
        if filteredIdioms.count == 1 {
            return "1 idiom"
        } else {
            return "\(filteredIdioms.count) idioms"
        }
    }
}
