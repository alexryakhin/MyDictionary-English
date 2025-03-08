//
//  IdiomsListContentView.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import SwiftUI
import CoreUserInterface
import CoreNavigation
import Core
import StoreKit

public struct IdiomsListContentView: PageView {

    public typealias ViewModel = IdiomsListViewModel

    @ObservedObject public var viewModel: ViewModel

    public init(viewModel: ViewModel) {
        self.viewModel = viewModel
    }

    public var contentView: some View {
        List {
            if !idiomsToShow().isEmpty {
                Section {
                    ForEach(idiomsToShow()) { idiomModel in
                        IdiomListCellView(
                            model: .init(
                                idiom: idiomModel.idiom,
                                isFavorite: idiomModel.isFavorite
                            )
                        )
                    }
                    .onDelete { offsets in
                        viewModel.deleteIdiom(atOffsets: offsets)
                    }
                } header: {
                    if let title = viewModel.filterState.title {
                        Text(title)
                    }
                } footer: {
                    if !idiomsToShow().isEmpty {
                        Text(idiomsCount)
                    }
                }
            }
            if viewModel.filterState == .search && idiomsToShow().count < 10 {
                Button {
                    addItem()
                } label: {
                    Text("Add '\(viewModel.searchText.trimmingCharacters(in: .whitespacesAndNewlines))'")
                }
            }
        }
        .listStyle(.insetGrouped)
        .if(viewModel.idioms.isNotEmpty, transform: { view in
            view.searchable(text: $viewModel.searchText, placement: .navigationBarDrawer(displayMode: .always))
        })
        .navigationTitle(TabBarItem.idioms.title)
        .listStyle(.insetGrouped)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                EditButton()
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
    }

    public func placeholderView(props: PageState.PlaceholderProps) -> some View {
        EmptyListView(
            label: "No idioms yet!",
            description: "Begin to add idioms to your list by tapping on plus icon in upper left corner"
        )
    }

    private func addItem() {
        viewModel.handle(.showAddIdiom)
    }

    private func idiomsToShow() -> [CoreIdiom] {
        switch viewModel.filterState {
        case .none:
            return viewModel.idioms
        case .favorite:
            return viewModel.favoriteIdioms
        case .search:
            return viewModel.searchResults
        }
    }

    private var idiomsCount: String {
        if idiomsToShow().count == 1 {
            return "1 idiom"
        } else {
            return "\(idiomsToShow().count) idioms"
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
                    viewModel.sortingState = .def
                    viewModel.sortIdioms()
                }
            } label: {
                if viewModel.sortingState == .def {
                    Image(systemName: "checkmark")
                }
                Text("Default")
            }
            Button {
                withAnimation {
                    viewModel.sortingState = .name
                    viewModel.sortIdioms()
                }
            } label: {
                if viewModel.sortingState == .name {
                    Image(systemName: "checkmark")
                }
                Text("Name")
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
