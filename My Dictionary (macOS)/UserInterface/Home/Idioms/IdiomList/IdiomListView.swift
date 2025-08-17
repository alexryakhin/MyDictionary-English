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
                    ActionButton(Loc.Idioms.addIdiom.localized(viewModel.searchText.trimmingCharacters(in: .whitespacesAndNewlines)), systemImage: "plus") {
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
                                        Label(Loc.Actions.delete.localized, systemImage: "trash")
                                    }
                                }
                        }
                    } else if viewModel.searchText.isNotEmpty {
                        ContentUnavailableView(
                            Loc.Idioms.noIdiomsFound.localized,
                            systemImage: "magnifyingglass",
                            description: Text(Loc.Idioms.addThisIdiom.localized)
                        )
                    } else {
                        ContentUnavailableView(
                            Loc.EmptyStates.noIdiomsYet.localized,
                            systemImage: "quote.bubble",
                            description: Text(Loc.Idioms.beginAddIdioms.localized)
                        )
                    }
                } trailingContent: {
                    HeaderButton(Loc.Idioms.addIdiom.localized, icon: "plus", size: .small, style: .borderedProminent) {
                        showingAddIdiom = true
                    }
                }
            }
            .padding(12)
        }
        .groupedBackground()
        .navigationTitle(Loc.Idioms.idioms.localized)
        .searchable(text: $viewModel.searchText, prompt: Loc.Idioms.searchIdioms.localized)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                // Sort button
                Menu {
                    Picker(Loc.Idioms.sort.localized, selection: $viewModel.sortingState) {
                        ForEach(SortingCase.idiomsSortingCases, id: \.self) { item in
                            Text(item.displayName)
                                .tag(item)
                        }
                    }
                    .pickerStyle(.inline)
                } label: {
                    Image(systemName: "arrow.up.arrow.down")
                }
                
                // Filter button
                Menu {
                    Picker(Loc.Idioms.filter.localized, selection: $viewModel.filterState) {
                        ForEach(IdiomFilterCase.availableCases, id: \.self) { item in
                            Text(item.displayName)
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
                .help(Loc.Idioms.addIdiom.localized)
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
            return Loc.Idioms.allIdioms.localized
        case .search:
            return Loc.Idioms.found.localized
        case .favorite:
            return Loc.Idioms.favoriteIdioms.localized
        }
    }
    
    private var idiomsCount: String {
        return Loc.Idioms.idiomsCount.localized(filteredIdioms.count)
    }
}
