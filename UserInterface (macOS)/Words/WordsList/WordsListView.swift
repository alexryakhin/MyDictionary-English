import SwiftUI

struct WordsListView: View {

    @ObservedObject private var viewModel: WordsViewModel
    @State private var isShowingAddView = false

    private var wordsFiltered: [CDWord] {
        viewModel.wordsFiltered
    }

    private var wordsCount: String {
        switch wordsFiltered.count {
        case 0: "No words"
        case 1: "1 word"
        default: "\(wordsFiltered.count) words"
        }
    }

    init(viewModel: WordsViewModel) {
        self._viewModel = ObservedObject(wrappedValue: viewModel)
    }

    var body: some View {
        List(selection: $viewModel.selectedWord) {
            ForEach(wordsFiltered) { word in
                WordsListCellView(word: word)
                    .tag(word)
            }
            .onDelete { offsets in
                viewModel.deleteWord(offsets: offsets)
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
        .background(Color(.textBackgroundColor))
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
}
