//
//  SharedMeaningEditView.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/9/25.
//

import SwiftUI

struct SharedMeaningEditView: View {
    
    @State private var meaning: SharedWordMeaning
    @Environment(\.dismiss) private var dismiss
    
    @State private var definitionText: String = ""
    @State private var examples: [String] = []
    @State private var newExampleText: String = ""
    
    @FocusState private var isDefinitionFocused: Bool
    @FocusState private var isNewExampleFocused: Bool
    
    private let dictionaryId: String
    private let wordId: String
    @StateObject private var dictionaryService = DictionaryService.shared
    
    init(meaning: SharedWordMeaning, dictionaryId: String, wordId: String) {
        self._meaning = State(wrappedValue: meaning)
        self.dictionaryId = dictionaryId
        self.wordId = wordId
    }
    
    var body: some View {
        ScrollViewWithCustomNavBar {
            LazyVStack(spacing: 12) {
                definitionSectionView
                examplesSectionView
                addExampleSectionView
            }
            .padding(12)
        } navigationBar: {
            NavigationBarView(
                title: Loc.Words.editMeaning,
                mode: .inline,
                showsDismissButton: true,
                trailingContent: {
                    HeaderButton(Loc.Actions.save, style: .borderedProminent) {
                        saveMeaning()
                    }
                    .disabled(definitionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            )
        }
        .groupedBackground()
        .onAppear {
            setupInitialData()
        }
    }
    
    private var definitionSectionView: some View {
        CustomSectionView(header: Loc.Words.WordDetails.definition, headerFontStyle: .stealth) {
            TextField(Loc.Words.WordDetails.definition, text: $definitionText, axis: .vertical)
                .textFieldStyle(.plain)
                .focused($isDefinitionFocused)
                .fontWeight(.semibold)
        } trailingContent: {
            if isDefinitionFocused {
                HeaderButton(Loc.Actions.done, size: .small) {
                    isDefinitionFocused = false
                }
            } else {
                AsyncHeaderButton(
                    Loc.Actions.listen,
                    icon: "speaker.wave.2.fill",
                    size: .small
                ) {
                    try await play(definitionText)
                }
                .disabled(TTSPlayer.shared.isPlaying || definitionText.isEmpty)
            }
        }
    }
    
    private var examplesSectionView: some View {
        CustomSectionView(
            header: examples.count > 1 ? "\(Loc.Words.examples) (\(examples.count))" : Loc.Words.example,
            headerFontStyle: .stealth,
            hPadding: .zero
        ) {
            if examples.isEmpty {
                Text(Loc.Words.noExamplesYet)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(vertical: 12, horizontal: 16)
            } else {
                FormWithDivider {
                    ForEach(Array(examples.enumerated()), id: \.offset) { index, example in
                        exampleRowView(example: example, index: index)
                    }
                }
            }
        }
    }
    
    private var addExampleSectionView: some View {
        CustomSectionView(header: Loc.Words.WordDetails.addExample, headerFontStyle: .stealth) {
            TextField(Loc.Words.typeNewExampleHere, text: $newExampleText, axis: .vertical)
                .textFieldStyle(.plain)
                .focused($isNewExampleFocused)
        } trailingContent: {
            if isNewExampleFocused {
                HeaderButton(Loc.Actions.done, size: .small) {
                    isNewExampleFocused = false
                }
            }
            
            HeaderButton(Loc.Actions.add, icon: "plus", size: .small) {
                addExample()
            }
            .disabled(newExampleText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
    }
    
    @ViewBuilder
    private func exampleRowView(example: String, index: Int) -> some View {
        HStack {
            Text("•")
                .foregroundColor(.secondary)
            
            Text(example)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            AsyncHeaderButton(
                icon: "speaker.wave.2.fill",
                size: .small
            ) {
                try await play(example)
            }
            .disabled(TTSPlayer.shared.isPlaying)
            
            HeaderButton(icon: "trash", color: .red, size: .small) {
                removeExample(at: index)
            }
        }
        .padding(vertical: 12, horizontal: 16)
    }
    
    // MARK: - Private Methods
    
    private func setupInitialData() {
        definitionText = meaning.definition
        examples = meaning.examples
    }
    
    private func saveMeaning() {
        Task {
            var updatedMeaning = meaning
            updatedMeaning.definition = definitionText.trimmingCharacters(in: .whitespacesAndNewlines)
            updatedMeaning.examples = examples
            
            // Update the meaning in the shared word
            if let word = dictionaryService.sharedWords[dictionaryId]?.first(where: { $0.id == wordId }) {
                var updatedWord = word
                if let index = updatedWord.meanings.firstIndex(where: { $0.id == meaning.id }) {
                    updatedWord.meanings[index] = updatedMeaning
                    await saveWordToFirebase(updatedWord)
                }
            }
            
            AnalyticsService.shared.logEvent(.meaningUpdated)
            dismiss()
        }
    }
    
    private func addExample() {
        let trimmedExample = newExampleText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedExample.isEmpty else { return }
        
        examples.append(trimmedExample)
        newExampleText = ""
        isNewExampleFocused = false
    }
    
    private func removeExample(at index: Int) {
        guard index < examples.count else { return }
        examples.remove(at: index)
    }
    
    private func saveWordToFirebase(_ updatedWord: SharedWord) async {
        do {
            // Update in-memory storage first
            await MainActor.run {
                if let index = dictionaryService.sharedWords[dictionaryId]?.firstIndex(where: {
                    $0.id == wordId
                }) {
                    dictionaryService.sharedWords[dictionaryId]?[index] = updatedWord
                }
            }

            // Update Firebase
            try await dictionaryService.updateWordInSharedDictionary(dictionaryId: dictionaryId, sharedWord: updatedWord)
        } catch {
            errorReceived(title: Loc.Errors.updateFailed, error)
        }
    }
    
    private func play(_ text: String) async throws {
        guard !text.isEmpty else { return }
        try await TTSPlayer.shared.play(
            text,
            targetLanguage: Locale.current.language.languageCode?.identifier
        )
    }
}
