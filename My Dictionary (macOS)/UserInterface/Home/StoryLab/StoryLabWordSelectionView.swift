//
//  StoryLabWordSelectionView.swift
//  My Dictionary
//
//  Created by Alexander Riakhin on 11/2/25.
//

import SwiftUI

struct StoryLabWordSelectionView: View {
    @Binding var selectedWords: Set<String>
    let targetLanguage: InputLanguage
    @Environment(\.dismiss) private var dismiss
    @StateObject private var wordsProvider = WordsProvider.shared
    @State private var searchText: String = ""

    var availableWords: [CDWord] {
        wordsProvider.words.filter { word in
            word.languageCode == targetLanguage.rawValue
        }
    }

    var filteredWords: [CDWord] {
        if searchText.isEmpty {
            return availableWords
        }
        return availableWords.filter { word in
            (word.wordItself?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }

    var body: some View {
        List {
            ForEach(filteredWords) { word in
                let isSelected = selectedWords.contains(word.wordItself ?? "")
                Button {
                    if isSelected {
                        selectedWords.remove(word.wordItself ?? "")
                    } else {
                        selectedWords.insert(word.wordItself ?? "")
                    }
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(word.wordItself ?? "")
                                .font(.body)
                            if let definition = word.meaningsArray.first?.definition {
                                Text(definition)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }
                        }
                        Spacer()
                        if isSelected {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.accent)
                        }
                    }
                    .contentShape(.rect)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(width: 500, height: 500)
        .safeAreaBarIfAvailable(edge: .top) {
            HStack {
                TextField(Loc.Actions.search, text: $searchText)
                    .textFieldStyle(.roundedBorder)
                HeaderButton(Loc.Actions.done) {
                    dismiss()
                }
            }
            .padding()
        }
        .overlay {
            if availableWords.isEmpty {
                ContentUnavailableView(
                    Loc.StoryLab.WordSelection.noWordsAvailable,
                    systemImage: "questionmark.circle",
                    description: Text(Loc.StoryLab.WordSelection.noWordsDescription)
                )
            } else if filteredWords.isEmpty {
                ContentUnavailableView(
                    Loc.StoryLab.WordSelection.noWordsFound,
                    systemImage: "questionmark.circle"
                )
            }
        }
        .groupedBackground()
        .navigationTitle(Loc.StoryLab.Configuration.selectWords)
        .toolbarTitleDisplayMode(.inlineLarge)
    }
}

