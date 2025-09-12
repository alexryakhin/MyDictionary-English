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
    }
    
    private func addSelectedWords() {
        isAdding = true
        
        // TODO: Implement adding words to dictionary
        // This would convert WordCollectionItem to Word and save to Core Data
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            isAdding = false
            dismiss()
        }
    }
}
