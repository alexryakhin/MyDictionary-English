//
//  SharedMeaningsListView.swift
//  My Dictionary
//
//  Created by Alexander Riakhin on 8/1/25.
//

import SwiftUI
import Combine

struct SharedMeaningsListView: View {

    @Environment(\.dismiss) private var dismiss
    @StateObject private var dictionaryService = DictionaryService.shared

    @Binding var word: SharedWord
    private let dictionaryId: String

    @State private var meaningToEdit: SharedWordMeaning?

    private var canEdit: Bool {
        guard let dictionary = dictionaryService.sharedDictionaries.first(where: { $0.id == dictionaryId }) else {
            return false
        }
        return dictionary.canEdit
    }

    init(word: Binding<SharedWord>, dictionaryId: String) {
        self._word = word
        self.dictionaryId = dictionaryId
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(Array(word.meanings.enumerated()), id: \.element.id) { index, meaning in
                    meaningCardView(meaning: meaning, index: index + 1)
                }
            }
            .padding(.horizontal, 16)
            .animation(.default, value: word.meanings)
        }
        .groupedBackground()
        .navigation(
            title: "\(Loc.Words.allMeanings) (\(word.meanings.count))",
            mode: .inline,
            showsBackButton: false,
            trailingContent: {
                if canEdit {
                    HeaderButton(icon: "plus", size: .medium, style: .borderedProminent) {
                        addNewMeaning()
                    }
                }
                HeaderButton(icon: "xmark", size: .medium) {
                    dismiss()
                }
            }
        )
        .sheet(item: $meaningToEdit) { meaning in
            SharedMeaningEditView(meaning: meaning, dictionaryId: dictionaryId, wordId: word.id)
        }
    }

    private func meaningCardView(meaning: SharedWordMeaning, index: Int) -> some View {
        CustomSectionView(header: "\(Loc.Words.meaning) \(index)", headerFontStyle: .stealth) {
            VStack(alignment: .leading, spacing: 12) {
                // Definition
                HStack {
                    Text(meaning.definition)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Spacer()

                    Menu {
                        Button {
                            Task {
                                try await play(meaning.definition)
                            }
                        } label: {
                            Label(Loc.Actions.listen, systemImage: "speaker.wave.2.fill")
                        }

                        if canEdit {
                            Button {
                                startEditing(meaning)
                            } label: {
                                Label(Loc.Actions.edit, systemImage: "pencil")
                            }

                            Divider()

                            Button(role: .destructive) {
                                deleteMeaningAlert(meaning)
                            } label: {
                                Label(Loc.Actions.delete, systemImage: "trash")
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .foregroundStyle(.secondary)
                            .padding(6)
                            .contentShape(Rectangle())
                    }
                }

                // Examples
                if !meaning.examples.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(Loc.Words.examples)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .fontWeight(.medium)

                        ForEach(Array(meaning.examples.enumerated()), id: \.offset) { exampleIndex, example in
                            HStack {
                                Text("\(exampleIndex + 1).")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .frame(width: 20, alignment: .leading)

                                Text(example)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .italic()

                                Spacer()

                                AsyncHeaderButton(
                                    icon: "speaker.wave.2.fill",
                                    size: .small
                                ) {
                                    try await play(example)
                                }
                                .disabled(TTSPlayer.shared.isPlaying)
                            }
                            .padding(.leading, 8)
                        }
                    }
                }
            }
        }
    }

    private func startEditing(_ meaning: SharedWordMeaning) {
        meaningToEdit = meaning
    }

    private func addNewMeaning() {
        let newMeaning = SharedWordMeaning(
            definition: Loc.Words.newDefinition,
            examples: [],
            order: word.meanings.count
        )

        var updatedWord = word
        updatedWord.meanings.append(newMeaning)

        Task {
            await saveWordToFirebase(updatedWord)
        }
    }

    private func deleteMeaningAlert(_ meaning: SharedWordMeaning) {
        AlertCenter.shared.showAlert(
            with: .deleteConfirmation(
                title: Loc.Words.deleteMeaning,
                message: Loc.Words.deleteMeaningConfirmation,
                onCancel: {
                    AnalyticsService.shared.logEvent(.meaningRemovingCanceled)
                },
                onDelete: {
                    deleteMeaning(meaning)
                    AnalyticsService.shared.logEvent(.meaningRemoved)
                }
            )
        )
    }

    private func deleteMeaning(_ meaning: SharedWordMeaning) {
        var updatedWord = word
        updatedWord.meanings.removeAll { $0.id == meaning.id }

        Task {
            await saveWordToFirebase(updatedWord)
        }
    }

    private func saveWordToFirebase(_ updatedWord: SharedWord) async {
        do {
            // Update in-memory storage first
            await MainActor.run {
                if let index = dictionaryService.sharedWords[dictionaryId]?.firstIndex(where: {
                    $0.id == word.id
                }) {
                    dictionaryService.sharedWords[dictionaryId]?[index] = updatedWord
                }
                word = updatedWord
            }

            // Update Firebase directly with SharedWord
            try await dictionaryService.updateWordInSharedDictionary(dictionaryId: dictionaryId, sharedWord: updatedWord)
        } catch {
            print("Failed to save word: \(error)")
        }
    }

    private func play(_ text: String) async throws {
        try await TTSPlayer.shared.play(
            text,
            targetLanguage: word.languageCode
        )
    }
}

