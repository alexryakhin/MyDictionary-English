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
        .navigationTitle(Loc.Settings.deleteWords)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(Loc.Actions.cancel) {
                    dismiss()
                }
            }
            
            ToolbarItem(placement: .confirmationAction) {
                if !viewModel.words.isEmpty {
                    Button(Loc.Settings.deleteAllWords) {
                        viewModel.showDeleteAllConfirmation = true
                    }
                    .foregroundColor(.red)
                }
            }
        }
        .searchable(text: $viewModel.searchText, prompt: Loc.Words.searchWords)
        .alert(Loc.Settings.deleteAllWordsConfirmation, isPresented: $viewModel.showDeleteAllConfirmation) {
            Button(Loc.Actions.cancel, role: .cancel) { }
            Button(Loc.Actions.delete, role: .destructive) {
                Task {
                    await viewModel.deleteAllWords()
                    dismiss()
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
                    dismiss()
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
        VStack(spacing: 16) {
            Image(systemName: "book.closed")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text(Loc.Settings.noWordsToDelete)
                .font(.title2)
                .fontWeight(.semibold)
            
            Text(Loc.Settings.noWordsToDeleteMessage)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var wordsListView: some View {
        VStack(spacing: 0) {
            // Selection controls
            if !viewModel.words.isEmpty {
                VStack(spacing: 12) {
                    HStack {
                        Button(viewModel.isAllSelected ? Loc.Actions.deselectAll : Loc.Actions.selectAll) {
                            viewModel.toggleSelectAll()
                        }
                        .foregroundColor(.accentColor)
                        
                        Spacer()
                        
                        if !viewModel.selectedWordIds.isEmpty {
                            Button(Loc.Settings.deleteSelectedWords) {
                                viewModel.showDeleteSelectedConfirmation = true
                            }
                            .foregroundColor(.red)
                            .fontWeight(.medium)
                        }
                    }
                    
                    Picker(Loc.Words.sort, selection: $viewModel.sortingState) {
                        ForEach(SortingCase.allCases, id: \.self) { sortCase in
                            Text(sortCase.displayName).tag(sortCase)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(.controlBackgroundColor))
                
                Divider()
            }
            
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
}

struct WordRowView: View {
    let word: CDWord
    let isSelected: Bool
    let onSelectionChanged: (Bool) -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: {
                onSelectionChanged(!isSelected)
            }) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .accentColor : .secondary)
                    .font(.title2)
            }
            .buttonStyle(PlainButtonStyle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(word.wordItself ?? "")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                if let definition = word.primaryDefinition, !definition.isEmpty {
                    Text(definition)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                HStack {
                    if let partOfSpeech = word.partOfSpeech, !partOfSpeech.isEmpty {
                        Text(partOfSpeech)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color(.controlBackgroundColor))
                            .cornerRadius(4)
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
