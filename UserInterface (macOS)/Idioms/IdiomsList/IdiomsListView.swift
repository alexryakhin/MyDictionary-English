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
            }

            if viewModel.filterState == .search && filteredIdioms.count < 10 {
                Button {
                    showAddView()
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
        .background(Color.backgroundColor)
        .animation(.default, value: filteredIdioms)
        .animation(.default, value: viewModel.filterState)
        .animation(.default, value: viewModel.sortingState)
        .safeAreaInset(edge: .top) {
            toolbar
                .colorWithGradient(
                    offset: 0,
                    interpolation: 0.1,
                    direction: .up
                )
        }
        .safeAreaInset(edge: .bottom) {
            if !filteredIdioms.isEmpty {
                Text(idiomCount)
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(12)
                    .colorWithGradient(
                        offset: 0,
                        interpolation: 0.2,
                        direction: .down
                    )
            }
        }
        .navigationTitle("Idioms")
        .sheet(isPresented: $isShowingAddView) {
            viewModel.searchText = ""
        } content: {
            AddIdiomView(inputText: viewModel.searchText)
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
            SearchField(text: _viewModel.projectedValue.searchText)
        }
        .padding(vertical: 12, horizontal: 16)
    }

    private var idiomCount: String {
        switch filteredIdioms.count {
        case 0: "No idioms"
        case 1: "1 idiom"
        default: "\(filteredIdioms.count) idioms"
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
