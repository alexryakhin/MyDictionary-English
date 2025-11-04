//
//  VocabularyWordsView.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin
//

import SwiftUI

struct VocabularyWordsView: View {
    let vocabularyWords: [VocabularyWord]
    let song: Song
    @Environment(\.dismiss) private var dismiss
    @StateObject private var navigationManager: NavigationManager = .shared
    
    @State private var selectedWords: Set<String> = []
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Instructions
                    instructionsSection
                    
                    // Vocabulary List
                    vocabularyListSection
                }
                .padding()
            }
            .groupedBackground()
            .navigation(
                title: "Vocabulary",
                mode: .inline,
                trailingContent: {
                    HeaderButton(Loc.Actions.done) {
                        dismiss()
                    }
                }
            )
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if !selectedWords.isEmpty {
                        Button(action: addSelectedWords) {
                            Text("Add \(selectedWords.count)")
                                .fontWeight(.semibold)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Instructions Section
    
    private var instructionsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Select words to add to your dictionary")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text("These vocabulary words were extracted from the song lyrics")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.secondarySystemGroupedBackground)
        .cornerRadius(12)
    }
    
    // MARK: - Vocabulary List Section
    
    private var vocabularyListSection: some View {
        CustomSectionView(header: "Vocabulary Words") {
            LazyVStack(spacing: 12) {
                ForEach(Array(vocabularyWords.enumerated()), id: \.offset) { index, word in
                    vocabularyWordCard(word: word, index: index)
                }
            }
            .padding(.vertical, 8)
        }
    }
    
    private func vocabularyWordCard(word: VocabularyWord, index: Int) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(word.word)
                        .font(.headline)
                    
                    Text(word.partOfSpeech)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .textCase(.lowercase)
                }
                
                Spacer()
                
                Button(action: {
                    if selectedWords.contains(word.word) {
                        selectedWords.remove(word.word)
                    } else {
                        selectedWords.insert(word.word)
                    }
                }) {
                    Image(systemName: selectedWords.contains(word.word) ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(selectedWords.contains(word.word) ? .accentColor : .secondary)
                        .font(.title3)
                }
            }
            
            Text(word.definition)
                .font(.body)
                .foregroundColor(.secondary)
            
            if !word.examples.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Examples:")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    
                    ForEach(word.examples.prefix(2), id: \.self) { example in
                        Text("• \(example)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .italic()
                    }
                }
            }
            
            if let context = word.context {
                Text("Context: \"\(context)\"")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .italic()
            }
            
            Divider()
            
            // Add to Dictionary Button
            Button(action: {
                addWordToDictionary(word)
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add to Dictionary")
                }
                .font(.subheadline)
                .foregroundColor(.accentColor)
            }
        }
        .padding()
        .background(Color.secondarySystemGroupedBackground)
        .cornerRadius(12)
    }
    
    // MARK: - Actions
    
    private func addWordToDictionary(_ word: VocabularyWord) {
        // Navigate to add word screen with pre-filled information
        navigationManager.navigationPath.append(
            NavigationDestination.addWord(word.word, true)
        )
        dismiss()
    }
    
    private func addSelectedWords() {
        // Add all selected words to dictionary
        for wordText in selectedWords {
            if let word = vocabularyWords.first(where: { $0.word == wordText }) {
                addWordToDictionary(word)
            }
        }
        selectedWords.removeAll()
    }
}

#Preview {
    VocabularyWordsView(
        vocabularyWords: [
            VocabularyWord(
                word: "carnaval",
                definition: "A festival or celebration, especially one held before Lent",
                examples: [
                    "El carnaval de Río es famoso en todo el mundo.",
                    "Durante el carnaval, las calles se llenan de música y color."
                ],
                partOfSpeech: "noun",
                context: "La vida es un carnaval"
            )
        ],
        song: Song(
            id: "1",
            title: "La Vida Es Un Carnaval",
            artist: "Celia Cruz",
            album: nil,
            albumArtURL: nil,
            duration: 233,
            previewURL: nil,
            serviceType: .appleMusic,
            serviceId: "1"
        )
    )
}

