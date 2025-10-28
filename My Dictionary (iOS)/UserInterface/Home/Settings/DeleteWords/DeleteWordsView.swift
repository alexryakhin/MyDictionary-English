import SwiftUI

struct DeleteWordsView: View {
    @StateObject private var viewModel = DeleteWordsViewModel()

    var body: some View {
        VStack(spacing: 0) {
            if viewModel.filteredWords.isEmpty {
                emptyStateView
            } else {
                wordsListView
            }
        }
        .groupedBackground()
        .navigation(
            title: Loc.Settings.deleteWords,
            mode: .inline,
            showsBackButton: true,
            trailingContent: {
                if !viewModel.words.isEmpty {
                    HeaderButton(Loc.Settings.deleteAllWords, color: .red) {
                        viewModel.showDeleteAllConfirmation = true
                    }
                }
            },
            bottomContent: {
                // Selection controls
                if !viewModel.words.isEmpty {
                    if #unavailable(iOS 26) {
                        InputView.searchView(Loc.Words.searchWords, searchText: $viewModel.searchText)
                    }
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
                                viewModel.showDeleteSelectedConfirmation = true
                            }
                        }
                        Spacer()
                    }
                }
            }
        )
        .if(isGlassAvailable) {
            $0.searchable(text: $viewModel.searchText, prompt: Loc.Words.searchWords)
        }
        .alert(Loc.Settings.deleteAllWordsConfirmation, isPresented: $viewModel.showDeleteAllConfirmation) {
            Button(Loc.Actions.cancel, role: .cancel) { }
            Button(Loc.Actions.delete, role: .destructive) {
                Task {
                    await viewModel.deleteAllWords()
                }
            }
        } message: {
            Text(Loc.Settings.deleteAllWordsConfirmationMessage(viewModel.words.count))
        }
        .alert(Loc.Settings.deleteWordsConfirmation, isPresented: $viewModel.showDeleteSelectedConfirmation) {
            Button(Loc.Actions.cancel, role: .cancel) { }
            Button(Loc.Actions.delete, role: .destructive) {
                Task {
                    await viewModel.deleteSelectedWords()
                }
            }
        } message: {
            Text(Loc.Settings.deleteWordsConfirmationMessage(viewModel.selectedWordIds.count))
        }
        .alert(Loc.Settings.wordsDeletedSuccessfully, isPresented: $viewModel.showSuccessAlert) {
            Button(Loc.Actions.ok) { }
        } message: {
            Text(Loc.Settings.wordsDeletedSuccessfullyMessage(viewModel.deletedCount))
        }
        .onAppear {
            viewModel.loadWords()
        }
    }

    private var emptyStateView: some View {
        ContentUnavailableView(
            Loc.Settings.noWordsToDelete,
            systemImage: "character.book.closed.fill",
            description: Text(Loc.Settings.noWordsToDeleteMessage)
        )
    }

    private var wordsListView: some View {
        List {
            Section {
                ForEach(viewModel.filteredWords, id: \.id) { word in
                    WordRowView(
                        word: word,
                        isSelected: viewModel.selectedWordIds.contains(word.id?.uuidString ?? ""),
                        onSelectionChanged: { isSelected in
                            viewModel.toggleSelection(for: word, isSelected: isSelected)
                        }
                    )
                }
            } header: {
                Text(Loc.Plurals.Words.wordsCount(viewModel.words.count))
            }
        }
        .listStyle(.insetGrouped)
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
                    .foregroundStyle(.primary)

                if let definition = word.primaryDefinition, !definition.isEmpty {
                    Text(definition)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                HStack {
                    if let partOfSpeech = word.partOfSpeech, !partOfSpeech.isEmpty {
                        TagView(text: partOfSpeech, size: .mini)
                    }

                    if let languageCode = word.languageCode, !languageCode.isEmpty {
                        TagView(text: word.languageDisplayName, color: .blue, size: .mini)
                    }

                    if word.isFavorite {
                        Image(systemName: "heart.fill")
                            .foregroundStyle(.red)
                            .font(.caption)
                    }

                    Spacer()
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button(action: {
                onSelectionChanged(!isSelected)
            }) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .accentColor : .secondary)
                    .font(.title2)
            }
            .buttonStyle(.plain)
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
