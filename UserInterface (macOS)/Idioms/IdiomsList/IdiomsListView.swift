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
        let selection = Binding {
            viewModel.selectedIdiomId
        } set: { idiomId in
            if let idiomId {
                viewModel.handle(.selectIdiom(id: idiomId))
            }
        }

        List(selection: selection) {
            ForEach(filteredIdioms) { idiom in
                IdiomsListCellView(idiom: idiom)
                    .tag(idiom.id)
            }
            .onDelete {
                viewModel.handle(.deleteIdiom(atOffsets: $0))
            }

            if viewModel.filterState == .search && filteredIdioms.count < 10 {
                Button {
                    showAddView()
                } label: {
                    Text("Add '\(viewModel.searchText.trimmingCharacters(in: .whitespacesAndNewlines))'")
                }
            }
        }
        .scrollContentBackground(.hidden)
        .animation(.default, value: viewModel.sortingState)
        .animation(.default, value: viewModel.filterState)
        .animation(.default, value: viewModel.idioms)
        .safeAreaInset(edge: .top) {
            toolbar
                .background(.regularMaterial)
        }
        .safeAreaInset(edge: .bottom) {
            if !filteredIdioms.isEmpty {
                Text(idiomCount)
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(12)
                    .background(.regularMaterial)
            }
        }
        .navigationTitle("Idioms")
        .sheet(isPresented: $isShowingAddView) {
            viewModel.searchText = ""
        } content: {
            AddIdiomView(inputText: viewModel.searchText)
        }
        .onDisappear {
            viewModel.handle(.deselectIdiom)
        }
    }

    // MARK: - Toolbar

    private var toolbar: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                sortMenu
                Button {
                    showAddView()
                } label: {
                    Image(systemName: "plus")
                        .foregroundColor(.accentColor)
                }
            }
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                TextField("Search", text: _viewModel.projectedValue.searchText)
                    .textFieldStyle(.plain)
            }
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .background(.separator)
            .clipShape(RoundedRectangle(cornerRadius: 4))
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
    }

    private var idiomCount: String {
        if filteredIdioms.count == 1 {
            return "1 idiom"
        } else {
            return "\(filteredIdioms.count) idioms"
        }
    }

    private func showAddView() {
        isShowingAddView = true
        AnalyticsService.shared.logEvent(.addIdiomTapped)
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

    private var sortMenu: some View {
        Menu {
            Section {
                Button {
                    viewModel.handle(.changeSorting(to: .def))
                } label: {
                    if viewModel.sortingState == .def {
                        Image(systemName: "checkmark")
                    }
                    Text("Default")
                }
                Button {
                    viewModel.handle(.changeSorting(to: .name))
                } label: {
                    if viewModel.sortingState == .name {
                        Image(systemName: "checkmark")
                    }
                    Text("Name")
                }
            } header: {
                Text("Sort by")
            }

            Section {
                Button {
                    viewModel.handle(.changeFilter(to: .none))
                } label: {
                    if viewModel.filterState == .none {
                        Image(systemName: "checkmark")
                    }
                    Text("None")
                }
                Button {
                    viewModel.handle(.changeFilter(to: .favorite))
                } label: {
                    if viewModel.filterState == .favorite {
                        Image(systemName: "checkmark")
                    }
                    Text("Favorites")
                }
            } header: {
                Text("Filter by")
            }
        } label: {
            Image(systemName: "arrow.up.arrow.down")
            Text(viewModel.sortingState.rawValue)
        }
    }
}
