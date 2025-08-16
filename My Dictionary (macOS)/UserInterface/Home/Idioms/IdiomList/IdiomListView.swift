//
//  IdiomListView.swift
//  My Dictionary
//
//  Created by Alexander Riakhin on 8/9/25.
//

import SwiftUI

struct IdiomListView: View {

    @StateObject private var viewModel = IdiomListViewModel()
    @StateObject private var sideBarManager = SideBarManager.shared
    @State private var showingAddIdiom: Bool = false

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                if viewModel.filterState == .search && filteredIdioms.count < 10 {
                    ActionButton("Add '\(viewModel.searchText.trimmingCharacters(in: .whitespacesAndNewlines))'", systemImage: "plus") {
                        showingAddIdiom = true
                    }
                }

                CustomSectionView(
                    header: filterStateTitle,
                    footer: idiomsCount,
                    hPadding: .zero
                ) {
                    if filteredIdioms.isNotEmpty {
                        ListWithDivider(
                            filteredIdioms,
                            dividerLeadingPadding: .zero,
                            dividerTrailingPadding: .zero
                        ) { idiomModel in
                            IdiomListCellView(idiom: idiomModel)
                                .id(idiomModel.id)
                                .onTap {
                                    sideBarManager.selectedIdiom = idiomModel
                                }
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
                    HeaderButton("Add idiom", icon: "plus", size: .small, style: .borderedProminent) {
                        showingAddIdiom = true
                    }
                }
            }
            .padding(12)
        }
        .groupedBackground()
        .navigationTitle("Idioms")
        .searchable(text: $viewModel.searchText, prompt: "Search idioms...")
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                // Sort button
                Menu {
                    Picker("Sort", selection: $viewModel.sortingState) {
                        ForEach(SortingCase.idiomsSortingCases, id: \.self) { item in
                            Text(item.rawValue)
                                .tag(item)
                        }
                    }
                    .pickerStyle(.inline)
                } label: {
                    Image(systemName: "arrow.up.arrow.down")
                }
                
                // Filter button
                Menu {
                    Picker("Filter", selection: $viewModel.filterState) {
                        ForEach(IdiomFilterCase.availableCases, id: \.self) { item in
                            Text(item.rawValue)
                                .tag(item)
                        }
                    }
                    .pickerStyle(.inline)
                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                }
                
                // Add Idiom button
                Button {
                    showingAddIdiom = true
                } label: {
                    Image(systemName: "plus")
                }
                .help("Add Idiom")
            }
        }
        .sheet(isPresented: $showingAddIdiom) {
            AddIdiomView(inputIdiom: viewModel.searchText)
        }
        .onAppear {
            AnalyticsService.shared.logEvent(.idiomsListOpened)
        }
    }
    
    // MARK: - Computed Properties
    
    private var filteredIdioms: [CDIdiom] {
        switch viewModel.filterState {
        case .none:
            return viewModel.searchResults
        case .search:
            return viewModel.searchResults
        case .favorite:
            return viewModel.favoriteIdioms
        }
    }
    
    private var filterStateTitle: String {
        switch viewModel.filterState {
        case .none:
            return "All Idioms"
        case .search:
            return "Search Results"
        case .favorite:
            return "Favorite Idioms"
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
