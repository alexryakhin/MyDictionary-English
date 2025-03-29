import SwiftUI
import CoreUserInterface__macOS_
import Shared
import Core

struct WordsListView: PageView {

    typealias ViewModel = WordsViewModel

    var viewModel: StateObject<ViewModel>
    @State private var isShowingAddView = false

    var _viewModel: ViewModel {
        viewModel.wrappedValue
    }

    var contentView: some View {
        List(selection: viewModel.projectedValue.selectedWord) {
            ForEach(_viewModel.wordsFiltered) { word in
                WordsListCellView(
                    model: .init(
                        word: word.word,
                        partOfSpeech: word.partOfSpeech.rawValue,
                        isFavorite: word.isFavorite,
                        isSelected: _viewModel.selectedWord?.id == word.id
                    )
                )
                .tag(word)
            }
            .onDelete { offsets in
                _viewModel.deleteWord(offsets: offsets)
            }

            if _viewModel.filterState == .search && _viewModel.wordsFiltered.count < 10 {
                Button {
                    isShowingAddView = true
                } label: {
                    Text("Add '\(_viewModel.searchText.trimmingCharacters(in: .whitespacesAndNewlines))'")
                }
            }
        }
        .animation(.default, value: _viewModel.wordsFiltered)
        .onDisappear {
            _viewModel.selectedWord = nil
        }
        .scrollContentBackground(.hidden)
        .safeAreaInset(edge: .top) {
            toolbar
                .background(.regularMaterial)
        }
        .safeAreaInset(edge: .bottom) {
            if !_viewModel.wordsFiltered.isEmpty {
                Text(_viewModel.wordsCount)
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(12)
                    .background(.regularMaterial)
            }
        }
        .navigationTitle("Words")
        .sheet(isPresented: $isShowingAddView) {
            _viewModel.searchText = ""
        } content: {
            AddWordView(inputWord: _viewModel.searchText)
        }
    }

    // MARK: - Toolbar

    private var toolbar: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                sortMenu
                Button {
                    isShowingAddView = true
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

    // MARK: - Sort Menu

    private var sortMenu: some View {
        Menu {
            Section {
                Button {
                    _viewModel.selectSortingState(.def)
                } label: {
                    if _viewModel.sortingState == .def {
                        Image(systemName: "checkmark")
                    }
                    Text("Default")
                }
                Button {
                    _viewModel.selectSortingState(.name)
                } label: {
                    if _viewModel.sortingState == .name {
                        Image(systemName: "checkmark")
                    }
                    Text("Name")
                }
                Button {
                    _viewModel.selectSortingState(.partOfSpeech)
                } label: {
                    if _viewModel.sortingState == .partOfSpeech {
                        Image(systemName: "checkmark")
                    }
                    Text("Part of speech")
                }
            } header: {
                Text("Sort by")
            }

            Section {
                Button {
                    _viewModel.selectFilterState(.none)
                } label: {
                    if _viewModel.filterState == .none {
                        Image(systemName: "checkmark")
                    }
                    Text("None")
                }
                Button {
                    _viewModel.selectFilterState(.favorite)
                } label: {
                    if _viewModel.filterState == .favorite {
                        Image(systemName: "checkmark")
                    }
                    Text("Favorites")
                }
            } header: {
                Text("Filter by")
            }

        } label: {
            Image(systemName: "arrow.up.arrow.down")
            Text(_viewModel.sortingState.rawValue)
        }
    }
}
