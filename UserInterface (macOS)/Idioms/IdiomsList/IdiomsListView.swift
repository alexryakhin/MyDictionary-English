import SwiftUI
import Core
import CoreUserInterface__macOS_
import Shared
import Services

struct IdiomsListView: PageView {

    typealias ViewModel = IdiomsViewModel

    var _viewModel: StateObject<ViewModel>
    var viewModel: ViewModel {
        _viewModel.wrappedValue
    }

    @State private var isShowingAddView = false

    init(viewModel: StateObject<ViewModel>) {
        self._viewModel = viewModel
    }

    var contentView: some View {
        List {
            ForEach(filteredIdioms) { idiom in
                Button {
                    viewModel.handle(.selectIdiom(id: idiom.id))
                    AnalyticsService.shared.logEvent(.idiomOpened)
                } label: {
                    IdiomsListCellView(
                        idiom: idiom,
                        isSelected: viewModel.selectedIdiomId == idiom.id
                    )
                }
                .buttonStyle(.borderless)
                .id(idiom.id)
                .listRowBackground(viewModel.selectedIdiomId == idiom.id ? Color.selectedContentBackgroundColor : Color.clear)
            }
            .onDelete {
                viewModel.handle(.deleteIdiom(atOffsets: $0))
                AnalyticsService.shared.logEvent(.idiomDeleteSwipeAction)
            }

            if viewModel.filterState == .search && filteredIdioms.count < 10 {
                Button {
                    isShowingAddView = true
                    AnalyticsService.shared.logEvent(.addIdiomTappedFromSearch)
                } label: {
                    Label("Add '\(viewModel.searchText.trimmingCharacters(in: .whitespacesAndNewlines))'", systemImage: "plus")
                }
                .buttonStyle(.borderless)
                .padding(vertical: 4, horizontal: 8)
                .multilineTextAlignment(.leading)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color.textBackgroundColor)
        .navigationTitle("Idioms")
        .navigationSubtitle(idiomCount)
        .animation(.default, value: filteredIdioms)
        .animation(.default, value: viewModel.filterState)
        .animation(.default, value: viewModel.sortingState)
        .searchable(text: _viewModel.projectedValue.searchText, placement: .automatic)
        .sheet(isPresented: $isShowingAddView) {
            viewModel.searchText = ""
        } content: {
            AddIdiomView(inputText: viewModel.searchText)
        }
        .toolbar {
            ToolbarItem(placement: .automatic) {
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
                .menuIndicator(.hidden)
            }
            ToolbarItem(placement: .automatic) {
                Button {
                    isShowingAddView = true
                    AnalyticsService.shared.logEvent(.addIdiomTapped)
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .onAppear {
            AnalyticsService.shared.logEvent(.idiomsListOpened)
        }
        .onChange(of: viewModel.sortingState) { _ in
            AnalyticsService.shared.logEvent(.idiomsListSortingSelected)
        }
        .onChange(of: viewModel.filterState) { _ in
            AnalyticsService.shared.logEvent(.idiomsListFilterSelected)
        }
    }

    private var idiomCount: String {
        switch filteredIdioms.count {
        case 0: "No idioms"
        case 1: "1 idiom"
        default: "\(filteredIdioms.count) idioms"
        }
    }

    private var filteredIdioms: [Idiom] {
        switch viewModel.filterState {
        case .none: viewModel.idioms
        case .favorite: viewModel.favoriteIdioms
        case .search: viewModel.searchResults
        @unknown default:
            fatalError("Unknown filter state: \(viewModel.filterState)")
        }
    }
}
