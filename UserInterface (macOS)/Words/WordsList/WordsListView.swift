import SwiftUI

struct WordsListView: View {

    typealias ViewModel = WordsViewModel

    var _viewModel: StateObject<ViewModel>
    var viewModel: ViewModel {
        _viewModel.wrappedValue
    }

    @State private var isShowingAddView = false

    private var wordsFiltered: [CDWord] {
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

    var body: some View {
        List {
            ForEach(wordsFiltered) { word in
                Button {
                    guard let id = word.id?.uuidString else { return }
                    viewModel.handle(.selectWord(wordID: id))
                    AnalyticsService.shared.logEvent(.wordOpened)
                } label: {
                    WordsListCellView(
                        word: word,
                        isSelected: viewModel.selectedWordId == word.id?.uuidString
                    )
                }
                .buttonStyle(.borderless)
                .id(word.id)
                .listRowBackground(viewModel.selectedWordId == word.id?.uuidString ? Color.selectedContentBackgroundColor : Color.clear)
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
                .padding(vertical: 4, horizontal: 8)
                .multilineTextAlignment(.leading)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color.textBackgroundColor)
        .animation(.default, value: wordsFiltered)
        .animation(.default, value: viewModel.filterState)
        .animation(.default, value: viewModel.sortingState)
        .navigationTitle("Words")
        .navigationSubtitle(wordsCount)
        .searchable(text: _viewModel.projectedValue.searchText, placement: .automatic)
        .sheet(isPresented: $isShowingAddView) {
            viewModel.searchText = ""
        } content: {
            AddWordView(inputWord: viewModel.searchText)
        }
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Menu {
                    Picker(selection: _viewModel.projectedValue.sortingState) {
                        ForEach(SortingCase.allCases, id: \.self) { item in
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
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .onAppear {
            AnalyticsService.shared.logEvent(.wordsListOpened)
        }
        .onChange(of: viewModel.sortingState) { _ in
            AnalyticsService.shared.logEvent(.wordsListSortingSelected)
        }
        .onChange(of: viewModel.filterState) { _ in
            AnalyticsService.shared.logEvent(.wordsListFilterSelected)
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
}
