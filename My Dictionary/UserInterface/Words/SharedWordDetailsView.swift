//
//  SharedWordDetailsView.swift
//  My Dictionary
//
//  Created by Alexander Riakhin on 8/1/25.
//

import SwiftUI
import Combine
import Flow

struct SharedWordDetailsView: View {

    @Environment(\.dismiss) private var dismiss

    @FocusState private var isPhoneticsFocused: Bool
    @FocusState private var isDefinitionFocused: Bool
    @FocusState private var isAddExampleFocused: Bool
    @State private var isAddingExample = false
    @State private var editingExampleIndex: Int?
    @State private var exampleTextFieldStr = ""

    // Mutable state for editable fields
    @State private var phoneticText: String = ""
    @State private var definitionText: String = ""
    @State private var examples: [String] = []
    
    @StateObject private var dictionaryService = DictionaryService.shared
    @StateObject private var authenticationService = AuthenticationService.shared

    @State private var word: SharedWord
    private let dictionaryId: String

    init(word: SharedWord, dictionaryId: String) {
        self._word = State(wrappedValue: word)
        self.dictionaryId = dictionaryId
        // Initialize mutable state with current word values
        self._phoneticText = State(wrappedValue: word.phonetic ?? "")
        self._definitionText = State(wrappedValue: word.definition)
        self._examples = State(wrappedValue: word.examples)
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                transcriptionSectionView
                partOfSpeechSectionView
                definitionSectionView

                languageSectionView
                examplesSectionView
                collaborativeFeaturesSection
            }
            .padding(.horizontal, 16)
            .animation(.default, value: word)
        }
        .groupedBackground()
        .navigation(
            title: "Word Details",
            mode: .inline,
            showsBackButton: true,
            trailingContent: {
                HeaderButton(icon: "trash") {
                    showDeleteAlert()
                }
                .tint(.red)
            },
            bottomContent: {
                Text(word.wordItself)
                    .font(.largeTitle)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .multilineTextAlignment(.leading)
                    .bold()
            }
        )
        .alert("Edit example", isPresented: .constant(editingExampleIndex != nil), presenting: editingExampleIndex) { index in
            TextField("Example", text: $exampleTextFieldStr)
            Button("Cancel", role: .cancel) {
                AnalyticsService.shared.logEvent(.wordExampleChangingCanceled)
            }
            Button("Save") {
                updateExample(at: index, text: exampleTextFieldStr)
                editingExampleIndex = nil
                exampleTextFieldStr = .empty
                AnalyticsService.shared.logEvent(.wordExampleChanged)
            }
        }
    }

    private var transcriptionSectionView: some View {
        CustomSectionView(header: "Transcription", headerFontStyle: .stealth) {
            TextField("Transcription", text: $phoneticText, axis: .vertical)
                .focused($isPhoneticsFocused)
                .fontWeight(.semibold)
        } trailingContent: {
            if isPhoneticsFocused {
                HeaderButton(text: "Done") {
                    isPhoneticsFocused = false
                    savePhonetic()
                }
            } else {
                HeaderButton(text: "Listen", icon: "speaker.wave.2.fill") {
                    play(word.wordItself, isWord: true)
                }
            }
        }
    }

    private var partOfSpeechSectionView: some View {
        CustomSectionView(header: "Part Of Speech", headerFontStyle: .stealth) {
            Text(word.partOfSpeech)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity, alignment: .leading)
        } trailingContent: {
            Menu {
                ForEach(PartOfSpeech.allCases, id: \.self) { partCase in
                    Button {
                        updatePartOfSpeech(partCase)
                    } label: {
                        Text(partCase.rawValue)
                    }
                }
            } label: {
                Text("Edit")
                    .font(.caption)
            }
            .buttonStyle(.bordered)
            .clipShape(Capsule())
        }
    }

    private var definitionSectionView: some View {
        CustomSectionView(header: "Definition", headerFontStyle: .stealth) {
            TextField("Definition", text: $definitionText, axis: .vertical)
                .focused($isDefinitionFocused)
                .fontWeight(.semibold)
        } trailingContent: {
            if isDefinitionFocused {
                HeaderButton(text: "Done") {
                    isDefinitionFocused = false
                    saveDefinition()
                    AnalyticsService.shared.logEvent(.wordDefinitionChanged)
                }
            } else {
                HeaderButton(text: "Listen", icon: "speaker.wave.2.fill") {
                    play(word.definition)
                    AnalyticsService.shared.logEvent(.wordDefinitionPlayed)
                }
            }
        }
    }



    @ViewBuilder
    private var languageSectionView: some View {
        if word.shouldShowLanguageLabel {
            CustomSectionView(header: "Language", headerFontStyle: .stealth) {
                HStack {
                    Text(word.languageDisplayName)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text(word.languageCode.uppercased())
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.2))
                        .foregroundStyle(.blue)
                        .clipShape(Capsule())
                }
            }
        }
    }
    


    private var examplesSectionView: some View {
        CustomSectionView(
            header: "Examples",
            headerFontStyle: .stealth,
            hPadding: 0
        ) {
            if !examples.isEmpty {
                FormWithDivider {
                    ForEach(Array(examples.enumerated()), id: \.offset) { index, example in
                        HStack {
                            Text(example)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            Menu {
                                Button {
                                    play(example)
                                    AnalyticsService.shared.logEvent(.wordExamplePlayed)
                                } label: {
                                    Label("Listen", systemImage: "speaker.wave.2.fill")
                                }
                                Button {
                                    exampleTextFieldStr = example
                                    editingExampleIndex = index
                                    AnalyticsService.shared.logEvent(.wordExampleChangeButtonTapped)
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                }
                                Section {
                                    Button(role: .destructive) {
                                        removeExample(at: index)
                                        AnalyticsService.shared.logEvent(.wordExampleRemoved)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            } label: {
                                Image(systemName: "ellipsis")
                                    .foregroundStyle(.secondary)
                                    .padding(6)
                                    .background(Color.black.opacity(0.01))
                            }
                        }
                        .padding(vertical: 12, horizontal: 16)
                        .contentShape(RoundedRectangle(cornerRadius: 16))
                    }
                }
            } else {
                Text("No examples yet")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
            }

            if isAddingExample {
                InputView(
                    "Type an example here",
                    submitLabel: .done,
                    text: $exampleTextFieldStr,
                    onSubmit: {
                        addExample(exampleTextFieldStr)
                        isAddingExample = false
                        exampleTextFieldStr = .empty
                        AnalyticsService.shared.logEvent(.wordExampleAdded)
                    },
                    trailingButtonLabel: "Cancel"
                ) {
                    // On cancel
                    isAddExampleFocused = false
                    isAddingExample = false
                    exampleTextFieldStr = .empty
                }
                .padding(.top, 12)
                .padding(.horizontal, 16)
            }
        } trailingContent: {
            if isAddingExample {
                HeaderButton(text: "Save", icon: "checkmark") {
                    addExample(exampleTextFieldStr)
                    isAddingExample = false
                    exampleTextFieldStr = .empty
                    AnalyticsService.shared.logEvent(.wordExampleAdded)
                }
            } else {
                HeaderButton(text: "Add example", icon: "plus") {
                    withAnimation {
                        isAddingExample.toggle()
                        AnalyticsService.shared.logEvent(.wordAddExampleTapped)
                    }
                }
            }
        }
    }
    
    // MARK: - Collaborative Features Section
    
    private var collaborativeFeaturesSection: some View {
        CustomSectionView(
            header: "Collaborative Features",
            headerFontStyle: .stealth
        ) {
            VStack(spacing: 16) {
                // Like and difficulty controls
                likeAndDifficultyControls
                
                // Stats summary
                statsSummary
                
                // View detailed stats button
                viewStatsButton
            }
        }
    }
    
    private var likeAndDifficultyControls: some View {
        VStack(spacing: 12) {
            // Like button
            HStack {
                Button {
                    toggleLike()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: word.isLikedBy(authenticationService.userEmail ?? "") ? "heart.fill" : "heart")
                            .foregroundStyle(word.isLikedBy(authenticationService.userEmail ?? "") ? .red : .secondary)
                        
                        Text(word.isLikedBy(authenticationService.userEmail ?? "") ? "Liked" : "Like")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                Text("\(word.likeCount) likes")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            // Difficulty selector
            HStack {
                Text("Your difficulty rating:")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Picker("Difficulty", selection: Binding(
                    get: { word.getDifficultyFor(authenticationService.userEmail ?? "") },
                    set: { updateDifficulty($0) }
                )) {
                    Text("New").tag(0)
                    Text("In Progress").tag(1)
                    Text("Needs Review").tag(2)
                    Text("Mastered").tag(3)
                }
                .pickerStyle(.menu)
                .font(.caption)
            }
        }
        .padding(16)
        .background(.background)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(.secondary.opacity(0.3), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var statsSummary: some View {
        HStack {
            StatSummaryCard(
                title: "Average Difficulty",
                value: String(format: "%.1f", word.averageDifficulty),
                icon: "chart.bar.fill"
            )
            
            StatSummaryCard(
                title: "Total Ratings",
                value: "\(word.difficulties.count)",
                icon: "person.2.fill"
            )
        }
    }
    
    private var viewStatsButton: some View {
        NavigationLink {
            SharedWordDifficultyStatsView(word: word, dictionaryId: dictionaryId)
        } label: {
            HStack {
                Image(systemName: "chart.bar.doc.horizontal")
                Text("View Detailed Statistics")
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(16)
            .background(.background)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(.secondary.opacity(0.3), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Private Methods

    private func savePhonetic() {
        Task {
            var updatedWord = word
            updatedWord = SharedWord(
                id: word.id,
                wordItself: word.wordItself,
                definition: word.definition,
                partOfSpeech: word.partOfSpeech,
                phonetic: phoneticText.isEmpty ? nil : phoneticText,
                examples: word.examples,
                languageCode: word.languageCode,
                timestamp: word.timestamp,
                updatedAt: Date(),
                addedByEmail: word.addedByEmail,
                addedByDisplayName: word.addedByDisplayName,
                addedAt: word.addedAt,
                likes: word.likes,
                difficulties: word.difficulties
            )
            
            await saveWordToFirebase(updatedWord)
        }
    }
    
    private func saveDefinition() {
        Task {
            var updatedWord = word
            updatedWord = SharedWord(
                id: word.id,
                wordItself: word.wordItself,
                definition: definitionText,
                partOfSpeech: word.partOfSpeech,
                phonetic: word.phonetic,
                examples: word.examples,
                languageCode: word.languageCode,
                timestamp: word.timestamp,
                updatedAt: Date(),
                addedByEmail: word.addedByEmail,
                addedByDisplayName: word.addedByDisplayName,
                addedAt: word.addedAt,
                likes: word.likes,
                difficulties: word.difficulties
            )
            
            await saveWordToFirebase(updatedWord)
        }
    }
    
    private func saveWordToFirebase(_ updatedWord: SharedWord) async {
        
        do {
            // Update in-memory storage first
            DispatchQueue.main.async {
                if let index = self.dictionaryService.sharedWords[dictionaryId]?.firstIndex(where: { $0.id == self.word.id }) {
                    self.dictionaryService.sharedWords[dictionaryId]?[index] = updatedWord
                }
                self.word = updatedWord
            }
            
            // Convert to Word and save to Firebase
            let wordForFirebase = Word(
                id: updatedWord.id,
                wordItself: updatedWord.wordItself,
                definition: updatedWord.definition,
                partOfSpeech: updatedWord.partOfSpeech,
                phonetic: updatedWord.phonetic,
                examples: updatedWord.examples,
                tags: [],
                difficultyLevel: 0,
                languageCode: updatedWord.languageCode,
                isFavorite: false,
                timestamp: updatedWord.timestamp,
                updatedAt: updatedWord.updatedAt,
                isSynced: true
            )
            
            try await dictionaryService.updateWordInSharedDictionary(
                dictionaryId: dictionaryId,
                word: wordForFirebase
            )
            
            print("✅ [SharedWordDetails] Word updated successfully")
            HapticManager.shared.triggerNotification(type: .success)
        } catch {
            print("❌ [SharedWordDetails] Failed to update word: \(error.localizedDescription)")
            errorReceived(title: "Update failed", error)
        }
    }

    private func play(_ text: String?, isWord: Bool = false) {
        Task { @MainActor in
            guard let text else { return }

            do {
                try await TTSPlayer.shared.play(
                    text,
                    targetLanguage: isWord
                    ? word.languageCode
                    : Locale.current.language.languageCode?.identifier
                )
            } catch {
                // Handle error if needed
            }
        }
    }

    private func updatePartOfSpeech(_ value: PartOfSpeech) {
        // Note: Part of speech is part of the shared word data, so we can't modify it
        // This would need to be handled differently if editing is required
        AnalyticsService.shared.logEvent(.partOfSpeechChanged)
    }

    private func addExample(_ example: String) {
        guard !example.isEmpty else { return }
        examples.append(example)
        saveExamples()
    }

    private func updateExample(at index: Int, text: String) {
        guard !text.isEmpty, index < examples.count else { return }
        examples[index] = text
        saveExamples()
    }

    private func removeExample(at index: Int) {
        guard index < examples.count else { return }
        examples.remove(at: index)
        saveExamples()
    }
    
    private func saveExamples() {
        Task {
            let updatedWord = SharedWord(
                id: word.id,
                wordItself: word.wordItself,
                definition: word.definition,
                partOfSpeech: word.partOfSpeech,
                phonetic: word.phonetic,
                examples: examples,
                languageCode: word.languageCode,
                timestamp: word.timestamp,
                updatedAt: Date(),
                addedByEmail: word.addedByEmail,
                addedByDisplayName: word.addedByDisplayName,
                addedAt: word.addedAt,
                likes: word.likes,
                difficulties: word.difficulties
            )
            
            await saveWordToFirebase(updatedWord)
        }
    }
    
    // MARK: - Collaborative Features Methods
    
    private func toggleLike() {
        Task {
            do {
                try await dictionaryService.toggleLike(for: word.id, in: dictionaryId)
                // The word will be updated via real-time listener
            } catch {
                print("❌ Failed to toggle like: \(error)")
            }
        }
    }
    
    private func updateDifficulty(_ difficulty: Int) {
        Task {
            do {
                try await dictionaryService.updateDifficulty(for: word.id, in: dictionaryId, difficulty: difficulty)
                // The word will be updated via real-time listener
            } catch {
                print("❌ Failed to update difficulty: \(error)")
            }
        }
    }

    private func showDeleteAlert() {
        AlertCenter.shared.showAlert(
            with: .deleteConfirmation(
                title: "Delete word",
                message: "Are you sure you want to delete this word?",
                onCancel: {
                    AnalyticsService.shared.logEvent(.wordRemovingCanceled)
                },
                onDelete: {
                    deleteWord()
                    dismiss()
                }
            )
        )
    }

    private func deleteWord() {
        
        Task { @MainActor in
            do {
                try await dictionaryService.deleteWordFromSharedDictionary(
                    dictionaryId: dictionaryId,
                    wordId: word.id
                )
                print("✅ [SharedWordDetails] Shared word deleted successfully")
                HapticManager.shared.triggerNotification(type: .success)
            } catch {
                print("❌ [SharedWordDetails] Failed to delete shared word: \(error.localizedDescription)")
                errorReceived(title: "Delete failed", error)
            }
        }
    }
    
    private func errorReceived(title: String, _ error: Error) {
        AlertCenter.shared.showAlert(
            with: .error(
                title: title,
                message: error.localizedDescription
            )
        )
    }
}

// MARK: - StatSummaryCard

struct StatSummaryCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.accent)
            
            Text(value)
                .font(.headline)
                .fontWeight(.semibold)
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(.background)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(.secondary.opacity(0.3), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
