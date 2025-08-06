//
//  IdiomListContentView.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import SwiftUI

struct IdiomListContentView: View {

    typealias ViewModel = IdiomListViewModel

    @ObservedObject var viewModel: ViewModel

    @State private var showingAddIdiom = false

    init(viewModel: ViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        List(selection: $viewModel.selectedIdiom) {
            if filteredIdioms.isNotEmpty {
                Section {
                    ForEach(filteredIdioms) { idiomModel in
                        IdiomListCellView(idiom: idiomModel)
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
                    showingAddIdiom.toggle()
                } label: {
                    Label("Add '\(viewModel.searchText.trimmingCharacters(in: .whitespacesAndNewlines))'", systemImage: "plus")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .clippedWithPaddingAndBackground()
                }
            }
        }
        .animation(.default, value: viewModel.sortingState)
        .overlay {
            if !filteredIdioms.isNotEmpty {
                ContentUnavailableView(
                    "No idioms yet",
                    systemImage: "quote.bubble",
                    description: Text("Begin to add idioms to your list by tapping on plus icon in upper left corner")
                )
            }
        }
        .animation(.default, value: viewModel.filterState)
        .animation(.default, value: viewModel.idioms)
        .navigationTitle("Idioms")
        .if(viewModel.idioms.isNotEmpty, transform: { view in
            view.searchable(text: $viewModel.searchText, placement: .navigationBarDrawer(displayMode: .always))
        })
        .toolbar {
            ToolbarItem {
                Button {
                    showingAddIdiom = true
                } label: {
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
                        ForEach(IdiomFilterCase.availableCases, id: \.self) { item in
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
        .sheet(isPresented: $showingAddIdiom) {
            AddIdiomContentView(inputIdiom: viewModel.searchText)
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
