import SwiftUI

struct DeleteWordsView: View {
    @StateObject private var viewModel = DeleteWordsViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            if viewModel.words.isEmpty {
                emptyStateView
            } else {
                wordsListView
            }
        }
        .safeAreaBarIfAvailable(edge: .top) {
            NavigationBarView(
                title: Loc.Settings.deleteWords,
                mode: .regular,
                showsDismissButton: true,
                trailingContent: {
                    if !viewModel.words.isEmpty {
                        HeaderButton(Loc.Settings.deleteAllWords, color: .red) {
                            AlertCenter.shared.showAlert(
                                with: .deleteConfirmation(
                                    title: Loc.Settings.deleteAllWordsConfirmation,
                                    message: Loc.Settings.deleteAllWordsConfirmationMessage(viewModel.words.count),
                                    onDelete: {
                                        Task {
                                            await viewModel.deleteAllWords()
                                        }
                                    }
                                )
                            )
                        }
                    }
                },
                bottomContent: {
                    if !viewModel.words.isEmpty {
                        HStack(spacing: 8) {
                            HeaderButtonMenu(viewModel.sortingState.displayName) {
                                Picker(Loc.Words.sort, selection: $viewModel.sortingState) {
                                    ForEach(SortingCase.allCases, id: \.self) { sortCase in
                                        Text(sortCase.displayName).tag(sortCase)
                                    }
                                }
                                .pickerStyle(.inline)
                            }

                            HeaderButton(viewModel.isAllSelected ? Loc.Actions.deselectAll : Loc.Actions.selectAll) {
                                viewModel.toggleSelectAll()
                            }

                            if !viewModel.selectedWordIds.isEmpty {
                                HeaderButton(Loc.Settings.deleteSelectedWords, color: .red) {
                                    AlertCenter.shared.showAlert(
                                        with: .deleteConfirmation(
                                            title: Loc.Settings.deleteWordsConfirmation,
                                            message: Loc.Settings.deleteWordsConfirmationMessage(viewModel.selectedWordIds.count),
                                            onDelete: {
                                                Task {
                                                    await viewModel.deleteSelectedWords()
                                                }
                                            }
                                        )
                                    )
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            )
        }
        .safeAreaBarIfAvailable {
            InputView.searchView(Loc.Words.searchWords, searchText: $viewModel.searchText)
                .padding(vertical: 12, horizontal: 16)
                .materialBackgroundIfNoGlassAvailable()
        }
        .frame(width: 500, height: 600)
        .onAppear {
            viewModel.loadWords()
        }
    }
    
    private var emptyStateView: some View {
        ContentUnavailableView(
            Loc.Settings.noWordsToDelete,
            systemImage: "book.closed",
            description: Text(Loc.Settings.noWordsToDeleteMessage)
        )
    }
    
    private var wordsListView: some View {
        // Words list
        List {
            ForEach(viewModel.filteredWords, id: \.id) { word in
                WordRowView(
                    word: word,
                    isSelected: viewModel.selectedWordIds.contains(word.id?.uuidString ?? ""),
                    onSelectionChanged: { isSelected in
                        viewModel.toggleSelection(for: word, isSelected: isSelected)
                    }
                )
            }
        }
        .listStyle(PlainListStyle())
    }
}

struct WordRowView: View {
    let word: CDWord
    let isSelected: Bool
    let onSelectionChanged: (Bool) -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(word.wordItself ?? "")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                if let definition = word.primaryDefinition?.nilIfEmpty {
                    Text(definition)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                HStack {
                    if let partOfSpeech = word.partOfSpeech?.nilIfEmpty {
                        TagView(text: partOfSpeech, size: .small)
                    }

                    if let languageCode = word.languageCode?.nilIfEmpty {
                        TagView(text: languageCode.uppercased(), color: .blue, size: .small)
                    }

                    if word.isFavorite {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                    
                    Spacer()
                }
            }
            
            Spacer()

            Button(action: {
                onSelectionChanged(!isSelected)
            }) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .accentColor : .secondary)
                    .font(.title2)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            onSelectionChanged(!isSelected)
        }
    }
}

#Preview {
    DeleteWordsView()
}
