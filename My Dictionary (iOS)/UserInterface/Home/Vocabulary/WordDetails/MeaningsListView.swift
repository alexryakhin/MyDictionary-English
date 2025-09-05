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
    @StateObject private var ttsPlayer = TTSPlayer.shared
    
    @State private var meaningToEdit: CDMeaning?
    
    init(word: CDWord) {
        self._word = StateObject(wrappedValue: word)
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(Array(word.meaningsArray.enumerated()), id: \.element.id) { index, meaning in
                    meaningCardView(meaning: meaning, index: index + 1)
                }
            }
            .padding(.horizontal, 16)
            .animation(.default, value: word.meaningsArray)
        }
        .groupedBackground()
        .navigation(
            title: "\(Loc.Words.allMeanings) (\(word.meaningsArray.count))",
            mode: .inline,
            showsBackButton: true,
            trailingContent: {
                HeaderButton(icon: "plus", size: .medium) {
                    addNewMeaning()
                }
            }
        )
        .sheet(item: $meaningToEdit) { meaning in
            MeaningEditView(meaning: meaning)
        }
    }
    
    private func meaningCardView(meaning: CDMeaning, index: Int) -> some View {
        CustomSectionView(
            header: "\(Loc.Words.meaning) \(index)",
            headerFontStyle: .stealth,
            hPadding: .zero
        ) {
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
                            deleteMeaning(meaning)
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
                }
                .padding(.horizontal, 16)

                // Examples
                if meaning.examplesDecoded.isNotEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(Array(meaning.examplesDecoded.enumerated()), id: \.offset) { _, example in
                            HStack {
                                Text("•")
                                    .foregroundColor(.secondary)
                                Menu {
                                    Button {
                                        Task {
                                            try await play(example)
                                        }
                                        AnalyticsService.shared.logEvent(.wordExamplePlayed)
                                    } label: {
                                        Label(Loc.Actions.listen, systemImage: "speaker.wave.2.fill")
                                    }
                                    .disabled(ttsPlayer.isPlaying)
                                } label: {
                                    Text(example)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .buttonStyle(.plain)
                                Spacer()
                            }
                            .padding(.leading, 16)
                        }
                    }
                }
            }
        }
    }
    
    private func startEditing(_ meaning: CDMeaning) {
        meaningToEdit = meaning
    }
    
    private func addNewMeaning() {
        do {
            let _ = try word.addMeaning(definition: Loc.Words.newDefinition, examples: [])
            saveContext()
        } catch {
            errorReceived(error)
        }
    }
    
    private func deleteMeaning(_ meaning: CDMeaning) {
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
        try await ttsPlayer.play(text)
    }
    
    private func saveContext() {
        do {
            try CoreDataService.shared.context.save()
        } catch {
            errorReceived(error)
        }
    }
}

