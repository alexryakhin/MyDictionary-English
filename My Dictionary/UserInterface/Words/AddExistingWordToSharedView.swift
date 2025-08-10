//
//  AddExistingWordToSharedView.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import SwiftUI

struct AddExistingWordToSharedView: View {

    struct Config: Hashable {
        let id = UUID()
        let word: CDWord
    }

    @Environment(\.dismiss) private var dismiss

    @State private var selectedDictionaryId: String? = nil
    @State private var showingDictionarySelection = false

    @StateObject private var word: CDWord
    @StateObject private var dictionaryService = DictionaryService.shared

    init(config: Config) {
        self._word = StateObject(wrappedValue: config.word)
    }

    var body: some View {
        ScrollView {
                VStack(spacing: 20) {
                    // Word Info Card
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "textformat")
                                .foregroundStyle(.accent)
                            Text("Word Details")
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
                                Text(word.partOfSpeech ?? "unknown")
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.accent.opacity(0.2))
                                    .cornerRadius(4)

                                if word.isFavorite {
                                    Image(systemName: "star.fill")
                                        .foregroundStyle(.yellow)
                                        .font(.caption)
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)

                    // Dictionary Selection
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "person.2")
                                .foregroundStyle(.green)
                            Text("Select Shared Dictionary")
                                .font(.headline)
                            Spacer()
                        }

                        Button {
                            showingDictionarySelection = true
                        } label: {
                            HStack {
                                Image(systemName: selectedDictionaryId == nil ? "person" : "person.2")
                                    .foregroundStyle(selectedDictionaryId == nil ? .blue : .green)

                                Text(selectedDictionaryId == nil ? "Select Dictionary" : "Dictionary Selected")
                                    .foregroundStyle(selectedDictionaryId == nil ? .blue : .primary)

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
                .navigationTitle("Add to Shared")
                .navigationBarTitleDisplayMode(.inline)
                .sheet(isPresented: $showingDictionarySelection) {
                    SharedDictionarySelectionView { dictionaryId in
                        selectedDictionaryId = dictionaryId
                    }
                }
                .onAppear {
                    dictionaryService.setupSharedDictionariesListener()
                }
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 12) {
                Button {
                    addWordToSelectedDictionary()
                } label: {
                    HStack {
                        Image(systemName: "plus")
                        Text("Add to Shared Dictionary")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(selectedDictionaryId != nil ? Color.blue : Color.gray)
                    .foregroundStyle(.white)
                    .cornerRadius(12)
                }
                .disabled(selectedDictionaryId == nil)

                Button("Cancel") {
                    dismiss()
                }
                .foregroundStyle(.secondary)
            }
        }
    }
    
    private func addWordToSelectedDictionary() {
        Task {
            word.sharedDictionaryId = selectedDictionaryId

            guard
                let dictionaryId = selectedDictionaryId,
                let wordData = Word(from: word)
            else {
                word.sharedDictionaryId = nil
                return
            }

            do {
                try await dictionaryService.addWordToSharedDictionary(
                    dictionaryId: dictionaryId,
                    word: wordData
                )
                HapticManager.shared.triggerNotification(type: .success)
            } catch {
                AlertCenter.shared.showAlert(with: .error(
                    title: "Can't share word",
                    message: error.localizedDescription
                ))
            }
        }
    }
} 
