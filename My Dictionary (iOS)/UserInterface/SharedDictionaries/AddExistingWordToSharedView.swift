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
                            TagView(
                                text: word.partOfSpeech ?? "unknown",
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
            ActionButton(
                "Add to Shared Dictionary",
                systemImage: "plus",
                style: .borderedProminent,
                isLoading: isLoading
            ) {
                print("🔘 [AddExistingWordToSharedView] Button pressed!")
                addWordToSelectedDictionary()
            }
            .disabled(selectedDictionaryId == nil)
            .padding(vertical: 12, horizontal: 16)
        }
    }

    private func addWordToSelectedDictionary() {
        Task { @MainActor in
            isLoading = true
            defer {
                isLoading = false
            }

            print("🔍 [AddExistingWordToSharedView] Starting to add word to shared dictionary")
            print("📝 [AddExistingWordToSharedView] Word: '\(word.wordItself ?? "nil")'")
            print("📝 [AddExistingWordToSharedView] Selected dictionary ID: \(selectedDictionaryId ?? "nil")")
            print("📝 [AddExistingWordToSharedView] Word language code: \(word.languageCode ?? "nil")")

            guard let dictionaryId = selectedDictionaryId else {
                print("❌ [AddExistingWordToSharedView] No dictionary ID selected")
                return
            }

            guard let wordData = Word(from: word) else {
                print("❌ [AddExistingWordToSharedView] Failed to convert CDWord to Word")
                print("📝 [AddExistingWordToSharedView] CDWord details:")
                print("  - ID: \(word.id?.uuidString ?? "nil")")
                print("  - Word: \(word.wordItself ?? "nil")")
                print("  - Definition: \(word.definition ?? "nil")")
                print("  - Part of speech: \(word.partOfSpeech ?? "nil")")
                print("  - Language code: \(word.languageCode ?? "nil")")
                return
            }

            print("✅ [AddExistingWordToSharedView] Successfully converted CDWord to Word")
            print("📝 [AddExistingWordToSharedView] Word data: \(wordData)")

            do {
                try await dictionaryService.addWordToSharedDictionary(
                    dictionaryId: dictionaryId,
                    word: wordData
                )
                print("✅ [AddExistingWordToSharedView] Word added successfully to shared dictionary")
                HapticManager.shared.triggerNotification(type: .success)
                dismiss()
            } catch {
                print("❌ [AddExistingWordToSharedView] Error adding word to shared dictionary: \(error.localizedDescription)")
                AlertCenter.shared.showAlert(with: .info(
                    title: "Can't share word",
                    message: error.localizedDescription
                ))
            }
        }
    }
}
