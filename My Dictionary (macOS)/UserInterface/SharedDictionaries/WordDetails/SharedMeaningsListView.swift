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
    
    @State private var word: SharedWord
    private let dictionaryId: String
    
    @State private var editingMeaning: SharedWordMeaning?
    @State private var editingDefinition: String = ""
    @State private var editingExamples: [String] = []
    @State private var showingDeleteAlert = false
    @State private var meaningToDelete: SharedWordMeaning?
    
    private var canEdit: Bool {
        guard let dictionary = dictionaryService.sharedDictionaries.first(where: { $0.id == dictionaryId }) else {
            return false
        }
        return dictionary.canEdit
    }
    
    init(word: SharedWord, dictionaryId: String) {
        self._word = State(wrappedValue: word)
        self.dictionaryId = dictionaryId
    }
    
    var body: some View {
        ScrollViewWithCustomNavBar {
            LazyVStack(spacing: 12) {
                ForEach(Array(word.meanings.enumerated()), id: \.element.id) { index, meaning in
                    meaningCardView(meaning: meaning, index: index + 1)
                }
            }
            .padding(12)
            .animation(.default, value: word.meanings)
        } navigationBar: {
            NavigationBarView(
                title: "All Meanings (\(word.meanings.count))",
                mode: .large,
                showsDismissButton: true,
                trailingContent: {
                    HeaderButton(icon: "plus", size: .medium) {
                        addNewMeaning()
                    }
                }
            )
        }
        .frame(minWidth: 600, minHeight: 400)
        .alert("Delete Meaning", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let meaning = meaningToDelete {
                    deleteMeaning(meaning)
                }
            }
        } message: {
            Text("Are you sure you want to delete this meaning? This action cannot be undone.")
        }
        .onAppear {
            // Start real-time listener for this specific word
            dictionaryService.startSharedWordListener(
                dictionaryId: dictionaryId,
                wordId: word.id
            ) { updatedWord in
                guard let updatedWord else { return }
                
                // Update the word state on the main thread
                DispatchQueue.main.async {
                    self.word = updatedWord
                }
            }
        }
        .onDisappear {
            // Stop the real-time listener when leaving the view
            dictionaryService.stopSharedWordListener(dictionaryId: dictionaryId, wordId: word.id)
        }
    }
    
    private func meaningCardView(meaning: SharedWordMeaning, index: Int) -> some View {
        CustomSectionView(header: "Meaning \(index)", headerFontStyle: .stealth) {
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
                            Label("Listen", systemImage: "speaker.wave.2.fill")
                        }
                        
                        if canEdit {
                            Button {
                                startEditing(meaning)
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            
                            Divider()
                            
                            Button(role: .destructive) {
                                meaningToDelete = meaning
                                showingDeleteAlert = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundStyle(.secondary)
                            .font(.title3)
                    }
                    .buttonStyle(.plain)
                }
                
                // Examples
                if !meaning.examples.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Examples")
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
        editingMeaning = meaning
        editingDefinition = meaning.definition
        editingExamples = meaning.examples
    }
    
    private func addNewMeaning() {
        let newMeaning = SharedWordMeaning(
            definition: "New definition",
            examples: [],
            order: word.meanings.count
        )
        
        var updatedWord = word
        updatedWord.meanings.append(newMeaning)
        
        Task {
            await saveWordToFirebase(updatedWord)
        }
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

