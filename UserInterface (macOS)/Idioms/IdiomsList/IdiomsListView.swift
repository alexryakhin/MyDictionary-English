import SwiftUI
import Core
import CoreUserInterface__macOS_
import Shared

struct IdiomsListView: PageView {

    typealias ViewModel = IdiomsViewModel

    var viewModel: StateObject<ViewModel>
    @State private var isShowingAddView = false
    @State private var selectedIdiom: Idiom?

    var contentView: some View {
        ScrollView(showsIndicators: false) {
            ListWithDivider(idiomsToShow()) { idiom in
                NavigationLink {
                    IdiomDetailsView(idiom: idiom)
                } label: {
                    IdiomsListCellView(
                        model: .init(
                            idiom: idiom.idiom,
                            isFavorite: idiom.isFavorite,
                            isSelected: selectedIdiom?.id == idiom.id
                        ) {
                            selectedIdiom = idiom
                        }
                    )
                }
            }

            if viewModel.wrappedValue.filterState == .search && idiomsToShow().count < 10 {
                Button {
                    showAddView()
                } label: {
                    Text("Add '\(viewModel.wrappedValue.searchText.trimmingCharacters(in: .whitespacesAndNewlines))'")
                }
            }
        }
        .safeAreaInset(edge: .top) {
            toolbar
                .background(.regularMaterial)
        }
        .safeAreaInset(edge: .bottom) {
            if !idiomsToShow().isEmpty {
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
            viewModel.wrappedValue.searchText = ""
        } content: {
            AddIdiomView(inputText: viewModel.wrappedValue.searchText)
        }
        .onDisappear {
            selectedIdiom = nil
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
                TextField("Search", text: viewModel.projectedValue.searchText)
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
        if idiomsToShow().count == 1 {
            return "1 idiom"
        } else {
            return "\(idiomsToShow().count) idioms"
        }
    }

    private func showAddView() {
        isShowingAddView = true
    }

    private func idiomsToShow() -> [Idiom] {
        switch viewModel.wrappedValue.filterState {
        case .none:
            return viewModel.wrappedValue.idioms
        case .favorite:
            return viewModel.wrappedValue.favoriteIdioms
        case .search:
            return viewModel.wrappedValue.searchResults
        }
    }

    private var sortMenu: some View {
        Menu {
            Section {
                Button {
                    withAnimation {
                        viewModel.wrappedValue.sortingState = .def
                        viewModel.wrappedValue.sortIdioms()
                    }
                } label: {
                    if viewModel.wrappedValue.sortingState == .def {
                        Image(systemName: "checkmark")
                    }
                    Text("Default")
                }
                Button {
                    withAnimation {
                        viewModel.wrappedValue.sortingState = .name
                        viewModel.wrappedValue.sortIdioms()
                    }
                } label: {
                    if viewModel.wrappedValue.sortingState == .name {
                        Image(systemName: "checkmark")
                    }
                    Text("Name")
                }
            } header: {
                Text("Sort by")
            }

            Section {
                Button {
                    withAnimation {
                        viewModel.wrappedValue.filterState = .none
                    }
                } label: {
                    if viewModel.wrappedValue.filterState == .none {
                        Image(systemName: "checkmark")
                    }
                    Text("None")
                }
                Button {
                    withAnimation {
                        viewModel.wrappedValue.filterState = .favorite
                    }
                } label: {
                    if viewModel.wrappedValue.filterState == .favorite {
                        Image(systemName: "checkmark")
                    }
                    Text("Favorites")
                }
            } header: {
                Text("Filter by")
            }

        } label: {
            Image(systemName: "arrow.up.arrow.down")
            Text(viewModel.wrappedValue.sortingState.rawValue)
        }
    }
}
