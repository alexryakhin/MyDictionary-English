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
        ScrollView {
            VStack(spacing: 16) {
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
                                .foregroundStyle(.accent)
                                .clipShape(Capsule())

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
                            .foregroundStyle(selectedDictionaryId == nil ? .blue : .green)

                        Text(selectedDictionaryId == nil ? "Select Dictionary" : "Dictionary Selected")
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
            .padding(.horizontal, 16)
        }
        .groupedBackground()
        .navigation(title: "Add to Shared", mode: .inline, showsBackButton: true)
        .sheet(isPresented: $showingDictionarySelection) {
            SharedDictionarySelectionView(selectedDictionaryId: selectedDictionaryId) { dictionaryId in
                selectedDictionaryId = dictionaryId
            }
        }
        .onAppear {
            dictionaryService.setupSharedDictionariesListener()
        }
        .safeAreaInset(edge: .bottom) {
            Button {
                addWordToSelectedDictionary()
            } label: {
                Label("Add to Shared Dictionary", systemImage: "plus")
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
                    .overlay {
                        if isLoading {
                            ProgressView()
                        }
                    }
            }
            .buttonStyle(.borderedProminent)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .disabled(selectedDictionaryId == nil)
            .allowsHitTesting(!isLoading)
            .padding(vertical: 12, horizontal: 16)
        }
    }

    private func addWordToSelectedDictionary() {
        Task { @MainActor in
            isLoading = true
            defer {
                isLoading = false
            }

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
                dismiss()
            } catch {
                AlertCenter.shared.showAlert(with: .error(
                    title: "Can't share word",
                    message: error.localizedDescription
                ))
            }
        }
    }
}
