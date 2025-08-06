//
//  SharedDictionaryWordDetailsView.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import SwiftUI

struct SharedDictionaryWordDetailsView: View {
    @StateObject private var dictionaryService = DictionaryService.shared
    @State private var isEditing = false
    @State private var editedWord: Word
    @State private var showingDeleteConfirmation = false
    @Environment(\.dismiss) private var dismiss
    
    let word: Word
    let dictionary: DictionaryService.SharedDictionary
    
    init(word: Word, dictionary: DictionaryService.SharedDictionary) {
        self.word = word
        self.dictionary = dictionary
        self._editedWord = State(initialValue: word)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Word Header
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(editedWord.wordItself)
                            .font(.largeTitle)
                            .fontWeight(.bold)

                        Spacer()

                        if editedWord.isFavorite {
                            Image(systemName: "heart.fill")
                                .foregroundColor(.red)
                                .font(.title2)
                        }
                    }

                    HStack {
                        Text(editedWord.partOfSpeech)
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        if let phonetic = editedWord.phonetic, !phonetic.isEmpty {
                            Text("[\(phonetic)]")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Text(editedWord.languageCode.uppercased())
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.2))
                            .foregroundColor(.blue)
                            .clipShape(Capsule())
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)

                // Definition
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "text.quote")
                            .foregroundColor(.blue)
                        Text("Definition")
                            .font(.headline)
                        Spacer()
                    }

                    Text(editedWord.definition)
                        .font(.body)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)

                // Examples
                if !editedWord.examples.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "list.bullet")
                                .foregroundColor(.green)
                            Text("Examples")
                                .font(.headline)
                            Spacer()
                        }

                        ForEach(editedWord.examples, id: \.self) { example in
                            Text("• \(example)")
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }

                // Tags
                if !editedWord.tags.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "tag")
                                .foregroundColor(.orange)
                            Text("Tags")
                                .font(.headline)
                            Spacer()
                        }

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(editedWord.tags, id: \.self) { tag in
                                    Text(tag)
                                        .font(.caption)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.orange.opacity(0.2))
                                        .foregroundColor(.orange)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }

                // Difficulty Level
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "star")
                            .foregroundColor(.yellow)
                        Text("Difficulty Level")
                            .font(.headline)
                        Spacer()
                    }

                    HStack {
                        Text(editedWord.difficultyLabel)
                            .font(.body)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(editedWord.difficultyColor.opacity(0.2))
                            .foregroundColor(editedWord.difficultyColor)
                            .clipShape(Capsule())

                        Spacer()
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)

                // Action Buttons
                if dictionary.canEdit {
                    VStack(spacing: 12) {
                        Button {
                            if isEditing {
                                saveChanges()
                            } else {
                                isEditing = true
                            }
                        } label: {
                            HStack {
                                Image(systemName: isEditing ? "checkmark" : "pencil")
                                Text(isEditing ? "Save Changes" : "Edit Word")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }

                        Button {
                            showingDeleteConfirmation = true
                        } label: {
                            HStack {
                                Image(systemName: "trash")
                                Text("Delete Word")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                    }
                    .padding(.top)
                }
            }
            .padding()
        }
        .navigationTitle("Word Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Done") {
                    dismiss()
                }
            }

            if isEditing {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        editedWord = word
                        isEditing = false
                    }
                }
            }
        }
        .alert("Delete Word", isPresented: $showingDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                deleteWord()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete '\(word.wordItself)'? This action cannot be undone.")
        }
    }
    
    private func saveChanges() {
        // Update the word in the shared dictionary
        dictionaryService.updateWordInSharedDictionary(dictionaryId: dictionary.id, word: editedWord) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    isEditing = false
                    HapticManager.shared.triggerNotification(type: .success)
                case .failure(let error):
                    print("Error updating word: \(error)")
                    // You might want to show an error alert here
                }
            }
        }
    }
    
    private func deleteWord() {
        dictionaryService.deleteWordFromSharedDictionary(dictionaryId: dictionary.id, wordId: word.id) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    dismiss()
                    HapticManager.shared.triggerNotification(type: .success)
                case .failure(let error):
                    print("Error deleting word: \(error)")
                    // You might want to show an error alert here
                }
            }
        }
    }
} 
