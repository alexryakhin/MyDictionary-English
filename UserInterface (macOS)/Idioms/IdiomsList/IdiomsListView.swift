import SwiftUI

struct IdiomListView: View {

    @ObservedObject private var viewModel: IdiomsViewModel
    @State private var isShowingAddView = false

    init(viewModel: IdiomsViewModel) {
        self._viewModel = ObservedObject(wrappedValue: viewModel)
    }

    var body: some View {
        List(selection: $viewModel.selectedIdiom) {
            ForEach(filteredIdioms) { idiom in
                IdiomListCellView(idiom: idiom)
                    .tag(idiom)
            }
            .onDelete {
                viewModel.deleteIdiom(atOffsets: $0)
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
        .background(Color(.textBackgroundColor))
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
        .alert(isPresented: _viewModel.projectedValue.isShowingAlert) {
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

    private var idiomCount: String {
        switch filteredIdioms.count {
        case 0: "No idioms"
        case 1: "1 idiom"
        default: "\(filteredIdioms.count) idioms"
        }
    }

    private var filteredIdioms: [CDIdiom] {
        switch viewModel.filterState {
        case .none: viewModel.idioms
        case .favorite: viewModel.favoriteIdioms
        case .search: viewModel.searchResults
        @unknown default:
            fatalError("Unknown filter state: \(viewModel.filterState)")
        }
    }
}
