//
//  AddCollectionToDictionaryView.swift
//  My Dictionary
//
//  Created by Alexander Riakhin on 9/12/25.
//

import SwiftUI

struct AddCollectionToDictionaryView: View {
    let collection: WordCollection
    @Environment(\.dismiss) private var dismiss
    @State private var selectedWords: Set<String> = []
    @State private var isAdding = false
    @State private var showSuccessAlert = false
    @State private var addedWordsCount = 0
    @State private var duplicateWordsCount = 0
    
    var body: some View {
        ScrollView {
            ListWithDivider(collection.words) { word in
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(word.text)
                            .font(.headline)
                        Text(word.definition)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }

                    Spacer()

                    Image(systemName: selectedWords.contains(word.id) ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(selectedWords.contains(word.id) ? .accent : .secondary)
                }
                .padding(vertical: 12, horizontal: 16)
                .contentShape(Rectangle())
                .onTapGesture {
                    if selectedWords.contains(word.id) {
                        selectedWords.remove(word.id)
                    } else {
                        selectedWords.insert(word.id)
                    }
                }
            }
            .clippedWithBackground(showShadow: true)
            .padding(vertical: 12, horizontal: 16)
        }
        .groupedBackground()
        .navigation(
            title: "Add Words",
            mode: .inline,
            trailingContent: {
                HeaderButton(Loc.Actions.cancel, size: .small) {
                    dismiss()
                }
                HeaderButton(Loc.Actions.add + " (\(selectedWords.count))", size: .small, style: .borderedProminent) {
                    addSelectedWords()
                }
                .disabled(selectedWords.count == 0)
            },
            bottomContent: {
                Text("Select words from '\(collection.title)' to add to your personal dictionary.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        )
        .alert("Import Complete", isPresented: $showSuccessAlert) {
            Button("OK") {
                dismiss()
            }
        } message: {
            if duplicateWordsCount > 0 {
                Text("Successfully added \(addedWordsCount) words to your dictionary. \(duplicateWordsCount) words were already in your dictionary and were skipped.")
            } else {
                Text("Successfully added \(addedWordsCount) words to your dictionary.")
            }
        }
    }
    
    private func addSelectedWords() {
        isAdding = true
        
        Task {
            do {
                let result = try await WordCollectionImportService.shared.importWords(
                    from: collection,
                    selectedWordIds: selectedWords
                )
                
                await MainActor.run {
                    addedWordsCount = result.addedCount
                    duplicateWordsCount = result.duplicateCount
                    isAdding = false
                    showSuccessAlert = true
                }
            } catch {
                await MainActor.run {
                    isAdding = false
                    // Handle error - could show error alert
                    print("Error importing words: \(error)")
                }
            }
        }
    }
}
