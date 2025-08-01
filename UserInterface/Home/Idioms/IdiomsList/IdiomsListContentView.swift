//
//  IdiomsListContentView.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import SwiftUI

struct IdiomsListContentView: View {

    typealias ViewModel = IdiomsListViewModel

    @ObservedObject var viewModel: ViewModel

    @State private var showingAddIdiom = false

    init(viewModel: ViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        Group {
            if filteredIdioms.isNotEmpty {
                ScrollView {
                    CustomSectionView(header: filterStateTitle, footer: idiomsCount) {
                        ListWithDivider(filteredIdioms) { idiomModel in
                            NavigationLink {
                                IdiomDetailsContentView(idiom: idiomModel)
                            } label: {
                                IdiomListCellView(
                                    model: .init(
                                        idiom: idiomModel.idiomItself ?? "",
                                        isFavorite: idiomModel.isFavorite
                                    )
                                )
                                .clippedWithPaddingAndBackground()
                                .contextMenu {
                                    Button(role: .destructive) {
                                        viewModel.handle(.deleteIdiom(idiom: idiomModel))
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                        }
                        .clippedWithBackground()
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
                .padding(vertical: 12, horizontal: 16)
                .animation(.default, value: viewModel.sortingState)
            } else {
                ContentUnavailableView(
                    "No idioms yet",
                    systemImage: "quote.bubble",
                    description: Text("Begin to add idioms to your list by tapping on plus icon in upper left corner")
                )
                .background(Color(.systemGroupedBackground))
            }
        }
        .animation(.default, value: viewModel.filterState)
        .animation(.default, value: viewModel.idioms)
        .background(Color(.systemGroupedBackground))
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
        .sheet(isPresented: $showingAddIdiom) {
            AddIdiomContentView(inputIdiom: viewModel.searchText)
        }
        .alert(isPresented: $viewModel.isShowingAlert) {
            Alert(
                title: Text(viewModel.alertModel.title),
                message: Text(viewModel.alertModel.message ?? ""),
                primaryButton: .default(Text(viewModel.alertModel.actionText ?? "OK")) {
                    viewModel.alertModel.action?()
                },
                secondaryButton: viewModel.alertModel.destructiveActionText != nil ? .destructive(Text(viewModel.alertModel.destructiveActionText!)) {
                    viewModel.alertModel.destructiveAction?()
                } : .cancel()
            )
        }

    }

    private var filteredIdioms: [CDIdiom] {
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
