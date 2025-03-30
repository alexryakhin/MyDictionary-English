import SwiftUI
import CoreUserInterface__macOS_
import Shared
import Core

struct WordsListView: PageView {

    typealias ViewModel = WordsViewModel

    var _viewModel: StateObject<ViewModel>
    var viewModel: ViewModel {
        _viewModel.wrappedValue
    }

    @State private var isShowingAddView = false

    private var wordsFiltered: [Word] {
        switch viewModel.filterState {
        case .none: viewModel.words
        case .favorite: viewModel.favoriteWords
        case .search: viewModel.searchResults
        @unknown default: fatalError("Unknown filter state")
        }
    }

    private var wordsCount: String {
        switch wordsFiltered.count {
        case 0: "No words"
        case 1: "1 word"
        default: "\(wordsFiltered.count) words"
        }
    }

    init(viewModel: StateObject<ViewModel>) {
        self._viewModel = viewModel
    }

    var contentView: some View {
        let selection = Binding {
            viewModel.selectedWordId
        } set: { wordID in
            if let wordID {
                viewModel.handle(.selectWord(wordID: wordID))
            }
        }

        List(selection: selection) {
            ForEach(wordsFiltered) { word in
                WordsListCellView(
                    model: .init(
                        word: word.word,
                        partOfSpeech: word.partOfSpeech.rawValue,
                        isFavorite: word.isFavorite,
                        isSelected: viewModel.selectedWord?.id == word.id
                    )
                )
                .tag(word)
            }
            .onDelete { offsets in
                viewModel.handle(.deleteWord(atOffsets: offsets))
            }

            if viewModel.filterState == .search && wordsFiltered.count < 10 {
                Button {
                    isShowingAddView = true
                } label: {
                    Label("Add '\(viewModel.searchText.trimmingCharacters(in: .whitespacesAndNewlines))'", systemImage: "plus")
                }
                .buttonStyle(.borderless)
            }
        }
        .background(Color.backgroundColor)
        .animation(.default, value: wordsFiltered)
        .animation(.default, value: viewModel.filterState)
        .animation(.default, value: viewModel.sortingState)
        .onDisappear {
            viewModel.handle(.deselectWord)
        }
        .scrollContentBackground(.hidden)
        .safeAreaInset(edge: .top) {
            toolbar
                .colorWithGradient(
                    offset: 0,
                    interpolation: 0.1,
                    direction: .up
                )
        }
        .safeAreaInset(edge: .bottom) {
            if !wordsFiltered.isEmpty {
                Text(wordsCount)
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
        .navigationTitle("Words")
        .sheet(isPresented: $isShowingAddView) {
            viewModel.searchText = ""
        } content: {
            AddWordView(inputWord: viewModel.searchText)
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
                TextField("Search", text: _viewModel.projectedValue.searchText)
                    .textFieldStyle(.plain)
            }
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .background(Color.textFieldColor)
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .background {
                RoundedRectangle(cornerRadius: 4)
                    .stroke(lineWidth: 2)
                    .foregroundStyle(Color.separatorColor)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
    }

    // MARK: - Sort Menu

    private var sortMenu: some View {
        Menu {
            Section {
                Button {
                    viewModel.handle(.selectSortingState(.def))
                } label: {
                    if viewModel.sortingState == .def {
                        Image(systemName: "checkmark")
                    }
                    Text("Default")
                }
                Button {
                    viewModel.handle(.selectSortingState(.name))
                } label: {
                    if viewModel.sortingState == .name {
                        Image(systemName: "checkmark")
                    }
                    Text("Name")
                }
                Button {
                    viewModel.handle(.selectSortingState(.partOfSpeech))
                } label: {
                    if viewModel.sortingState == .partOfSpeech {
                        Image(systemName: "checkmark")
                    }
                    Text("Part of speech")
                }
            } header: {
                Text("Sort by")
            }

            Section {
                Button {
                    viewModel.handle(.selectFilterState(.none))
                } label: {
                    if viewModel.filterState == .none {
                        Image(systemName: "checkmark")
                    }
                    Text("None")
                }
                Button {
                    viewModel.handle(.selectFilterState(.favorite))
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
