//
//  AddExistingWordToSharedView.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import SwiftUI

struct AddExistingWordToSharedView: View {

    @Environment(\.dismiss) private var dismiss

    @State private var selectedDictionaryId: String? = nil
    @State private var showingDictionarySelection = false
    @State private var isLoading = false

    @StateObject private var word: CDWord
    @StateObject private var dictionaryService = DictionaryService.shared

    init(word: CDWord) {
        self._word = StateObject(wrappedValue: word)
    }

    var body: some View {
        ScrollViewWithCustomNavBar {
            VStack(spacing: 16) {
                // Word Info Card
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "textformat")
                            .foregroundStyle(.accent)
                        Text(Loc.Words.wordDetails)
                            .font(.headline)
                        Spacer()
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text(word.wordItself ?? "")
                            .font(.title2)
                            .fontWeight(.semibold)

                        Text(word.definition ?? "")
                            .font(.body)
                            .foregroundStyle(.secondary)

                        if let phonetic = word.phonetic, !phonetic.isEmpty {
                            Text("[\(phonetic)]")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        HStack {
                            TagView(
                                text: PartOfSpeech(rawValue: word.partOfSpeech).displayName,
                                color: .accent,
                                size: .small
                            )

                            if word.isFavorite {
                                Image(systemName: "heart.fill")
                                    .foregroundStyle(.accent)
                                    .font(.caption)
                            }
                        }
                    }
                }
                .clippedWithPaddingAndBackground()

                // Dictionary Selection
                Button {
                    showingDictionarySelection = true
                } label: {
                    HStack {
                        Image(systemName: selectedDictionaryId == nil ? "person" : "person.2")
                            .foregroundStyle(selectedDictionaryId == nil ? .blue : .accent)

                        Text(selectedDictionaryId == nil ? Loc.SharedDictionaries.SharedDictionarySelection.selectDictionary : Loc.SharedDictionaries.SharedDictionarySelection.dictionarySelected)
                            .foregroundStyle(selectedDictionaryId == nil ? .blue : .primary)

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .clippedWithPaddingAndBackground(cornerRadius: 16)
                }
                .buttonStyle(.plain)
            }
            .padding(12)
        } navigationBar: {
            NavigationBarView(
                title: Loc.SharedDictionaries.SharedDictionarySelection.addToShared,
                trailingContent: {
                    AsyncHeaderButton(
                        Loc.SharedDictionaries.addToSharedDictionary,
                        style: .borderedProminent
                    ) {
                        try await addWordToSelectedDictionary()
                    }
                    .disabled(selectedDictionaryId == nil)
                    .help(Loc.SharedDictionaries.SharedDictionarySelection.addWordToSharedDictionary)
                }
            )
        }
        .groupedBackground()
        .sheet(isPresented: $showingDictionarySelection) {
            SharedDictionarySelectionView(selectedDictionaryId: selectedDictionaryId) { dictionaryId in
                selectedDictionaryId = dictionaryId
            }
        }
        .onAppear {
            dictionaryService.setupSharedDictionariesListener()
        }
    }

    private func addWordToSelectedDictionary() async throws {
        guard let dictionaryId = selectedDictionaryId, let wordData = Word(from: word) else { return }

        try await dictionaryService.addWordToSharedDictionary(
            dictionaryId: dictionaryId,
            word: wordData
        )
        dismiss()
    }
}
