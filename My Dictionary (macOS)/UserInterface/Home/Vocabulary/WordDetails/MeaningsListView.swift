//
//  MeaningsListView.swift
//  My Dictionary
//
//  Created by Alexander Riakhin on 8/1/25.
//

import SwiftUI
import Combine

struct MeaningsListView: View {

    @Environment(\.dismiss) private var dismiss
    @StateObject var word: CDWord

    @State private var editingMeaning: CDMeaning?
    @State private var editingDefinition: String = ""
    @State private var editingExamples: [String] = []
    @State private var meaningToEdit: CDMeaning?

    init(word: CDWord) {
        self._word = StateObject(wrappedValue: word)
    }

    var body: some View {
        ScrollViewWithCustomNavBar {
            LazyVStack(spacing: 12) {
                ForEach(Array(word.meaningsArray.enumerated()), id: \.element.id) { index, meaning in
                    meaningCardView(meaning: meaning, index: index + 1)
                }
            }
            .padding(12)
            .animation(.default, value: word.meaningsArray)
        } navigationBar: {
            NavigationBarView(
                title: "\(Loc.Words.allMeanings) (\(word.meaningsArray.count))",
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
        .groupedBackground()
    }

    private func meaningCardView(meaning: CDMeaning, index: Int) -> some View {
        CustomSectionView(header: "\(Loc.Words.meaning) \(index)", headerFontStyle: .stealth) {
            VStack(alignment: .leading, spacing: 12) {
                // Definition
                HStack {
                    Text(meaning.definition ?? "")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Spacer()

                    Menu {
                        Button {
                            Task {
                                try await play(meaning.definition ?? "")
                            }
                        } label: {
                            Label(Loc.Actions.listen, systemImage: "speaker.wave.2.fill")
                        }

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
                                .tint(.red)
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .foregroundStyle(.secondary)
                            .padding(6)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }

                // Examples
                if !meaning.examplesDecoded.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(Loc.Words.examples)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .fontWeight(.medium)

                        ForEach(Array(meaning.examplesDecoded.enumerated()), id: \.offset) { exampleIndex, example in
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

    private func startEditing(_ meaning: CDMeaning) {
        editingMeaning = meaning
        editingDefinition = meaning.definition ?? ""
        editingExamples = meaning.examplesDecoded
    }

    private func addNewMeaning() {
        do {
            let _ = try word.addMeaning(definition: Loc.Words.newDefinition, examples: [])
            saveContext()
        } catch {
            errorReceived(error)
        }
    }

    private func deleteMeaningAlert(_ meaning: CDMeaning) {
        AlertCenter.shared.showAlert(
            with: .deleteConfirmation(
                title: Loc.Words.deleteMeaning,
                message: Loc.Words.deleteMeaningConfirmation,
                onCancel: {
                    AnalyticsService.shared.logEvent(.meaningRemovingCanceled)
                },
                onDelete: {
                    word.removeMeaning(meaning)
                    saveContext()
                    AnalyticsService.shared.logEvent(.meaningRemoved)
                }
            )
        )
    }

    private func play(_ text: String) async throws {
        try await TTSPlayer.shared.play(
            text,
            targetLanguage: word.languageCode ?? Locale.current.language.languageCode?.identifier
        )
    }

    private func saveContext() {
        do {
            try CoreDataService.shared.context.save()
        } catch {
            errorReceived(error)
        }
    }
}

