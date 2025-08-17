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

    @State private var showingDetailedStatistics: Bool = false

    // Mutable state for editable fields
    @State private var phoneticText: String = ""
    @State private var definitionText: String = ""
    @State private var examples: [String] = []

    @StateObject private var dictionaryService = DictionaryService.shared
    @StateObject private var authenticationService = AuthenticationService.shared

    @State private var word: SharedWord
    private let dictionaryId: String

    private var canEdit: Bool {
        guard let dictionary = dictionaryService.sharedDictionaries.first(where: { $0.id == dictionaryId }) else {
            return false
        }
        return dictionary.canEdit
    }

    init(word: SharedWord, dictionaryId: String) {
        self._word = State(wrappedValue: word)
        self.dictionaryId = dictionaryId
        // Initialize mutable state with current word values
        self._phoneticText = State(wrappedValue: word.phonetic ?? "")
        self._definitionText = State(wrappedValue: word.definition)
        self._examples = State(wrappedValue: word.examples)
    }

    var body: some View {
        ScrollViewWithCustomNavBar {
            LazyVStack(spacing: 12) {
                transcriptionSectionView
                partOfSpeechSectionView
                definitionSectionView

                languageSectionView
                examplesSectionView
                collaborativeFeaturesSection
            }
            .padding(12)
            .animation(.default, value: word)
        } navigationBar: {
            Text(word.wordItself)
                .font(.largeTitle)
                .frame(maxWidth: .infinity, alignment: .leading)
                .multilineTextAlignment(.leading)
                .bold()
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .padding(.top, 16)
        }
        .groupedBackground()
        .navigationTitle("Word Details")
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                // Like button
                Button {
                    toggleLike()
                } label: {
                    HStack {
                        Image(systemName: word.isLikedBy(authenticationService.userEmail ?? "") ? "heart.fill" : "heart")
                        Text(word.likeCount.formatted())
                    }
                }
                .help("Toggle Like")

                if canEdit {
                    // Delete button
                    Button {
                        showDeleteAlert()
                    } label: {
                        Image(systemName: "trash")
                            .foregroundStyle(.red)
                    }
                    .help("Delete Word")
                }
            }
        }
        .sheet(item: $editingExampleIndex) { index in
            EditExampleAlert(
                exampleText: $exampleTextFieldStr,
                onCancel: {
                    AnalyticsService.shared.logEvent(.wordExampleChangingCanceled)
                    editingExampleIndex = nil
                },
                onSave: {
                    updateExample(at: index, text: exampleTextFieldStr)
                    editingExampleIndex = nil
                    exampleTextFieldStr = .empty
                    AnalyticsService.shared.logEvent(.wordExampleChanged)
                }
            )
        }
        .sheet(isPresented: $showingDetailedStatistics) {
            SharedWordDifficultyStatsView(word: word)
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
                    // Also update the local state variables to keep them in sync
                    self.phoneticText = updatedWord.phonetic ?? ""
                    self.definitionText = updatedWord.definition
                    self.examples = updatedWord.examples
                }
            }
        }
        .onDisappear {
            // Stop the real-time listener when leaving the view
            dictionaryService.stopSharedWordListener(dictionaryId: dictionaryId, wordId: word.id)
        }
    }

    private var transcriptionSectionView: some View {
        CustomSectionView(header: "Transcription", headerFontStyle: .stealth) {
            if canEdit {
                TextField("Transcription", text: $phoneticText, axis: .vertical)
                    .textFieldStyle(.plain)
                    .focused($isPhoneticsFocused)
                    .fontWeight(.semibold)
            } else {
                Text(phoneticText.nilIfEmpty ?? "No transcription")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fontWeight(.semibold)
            }
        } trailingContent: {
            if isPhoneticsFocused {
                HeaderButton("Done", size: .small) {
                    isPhoneticsFocused = false
                    savePhonetic()
                }
            } else {
                HeaderButton("Listen", icon: "speaker.wave.2.fill", size: .small) {
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
            if canEdit {
                HeaderButtonMenu("Edit", size: .small) {
                    ForEach(PartOfSpeech.allCases, id: \.self) { partCase in
                        Button {
                            updatePartOfSpeech(partCase)
                        } label: {
                            Text(partCase.rawValue)
                        }
                    }
                }
            }
        }
    }

    private var definitionSectionView: some View {
        CustomSectionView(header: "Definition", headerFontStyle: .stealth) {
            if canEdit {
                TextField("Definition", text: $definitionText, axis: .vertical)
                    .textFieldStyle(.plain)
                    .focused($isDefinitionFocused)
                    .fontWeight(.semibold)
            } else {
                Text(definitionText.nilIfEmpty ?? "No definition")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fontWeight(.semibold)
            }
        } trailingContent: {
            if isDefinitionFocused {
                HeaderButton("Done", size: .small) {
                    isDefinitionFocused = false
                    saveDefinition()
                    AnalyticsService.shared.logEvent(.wordDefinitionChanged)
                }
            } else {
                HeaderButton("Listen", icon: "speaker.wave.2.fill", size: .small) {
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

                    TagView(
                        text: word.languageCode.uppercased(),
                        color: .blue,
                        size: .mini
                    )
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
                                if canEdit {
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
                                }
                            } label: {
                                Image(systemName: "ellipsis")
                                    .foregroundStyle(.secondary)
                                    .padding(6)
                                    .background(Color.black.opacity(0.01))
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(vertical: 12, horizontal: 16)
                        .contentShape(RoundedRectangle(cornerRadius: 16))
                    }
                }
            } else {
                Text(Loc.Words.noExamplesYet.localized)
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
            if canEdit {
                if isAddingExample {
                    HeaderButton("Save", icon: "checkmark", size: .small) {
                        addExample(exampleTextFieldStr)
                        isAddingExample = false
                        exampleTextFieldStr = .empty
                        AnalyticsService.shared.logEvent(.wordExampleAdded)
                    }
                } else {
                    HeaderButton("Add example", icon: "plus", size: .small) {
                        withAnimation {
                            isAddingExample.toggle()
                            AnalyticsService.shared.logEvent(.wordAddExampleTapped)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Collaborative Features Section

    private var collaborativeFeaturesSection: some View {
        CustomSectionView(
            header: "Collaborative Features",
            headerFontStyle: .stealth,
            footer: word.addedByDisplayText
        ) {
            VStack(spacing: 12) {
                // User's stats
                likeAndDifficultyControls

                // Stats summary
                statsSummary

                // View detailed stats button
                viewStatsButton
            }
            .padding(.bottom, 12)
        }
    }

    @ViewBuilder
    private var likeAndDifficultyControls: some View {
        let userScore = word.getDifficultyFor(authenticationService.userEmail ?? "")
        let userDifficulty = Difficulty(score: userScore)

        HStack(spacing: 12) {
            StatSummaryCard(
                title: "Your score",
                value: userScore.formatted(),
                icon: "trophy.fill"
            )

            StatSummaryCard(
                title: "Your status",
                value: userDifficulty.displayName,
                icon: userDifficulty.imageName
            )
        }
    }

    private var statsSummary: some View {
        HStack(spacing: 12) {
            StatSummaryCard(
                title: "Average Score",
                value: word.averageDifficulty.formatted(),
                icon: "chart.bar.fill"
            )

            StatSummaryCard(
                title: "Total Ratings",
                value: word.difficulties.count.formatted(),
                icon: "person.2.fill"
            )
        }
    }

    private var viewStatsButton: some View {
        ActionButton(
            "View Detailed Statistics",
            systemImage: "chart.bar.doc.horizontal"
        ) {
            showingDetailedStatistics = true
        }
    }

    // MARK: - Private Methods

    private func savePhonetic() {
        Task {
            var updatedWord = word
            updatedWord.phonetic = phoneticText
            await saveWordToFirebase(updatedWord)
        }
    }

    private func saveDefinition() {
        Task {
            var updatedWord = word
            updatedWord.definition = definitionText
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
                errorReceived(error)
            }
        }
    }

    private func updatePartOfSpeech(_ value: PartOfSpeech) {
        Task {
            var updatedWord = word
            updatedWord.partOfSpeech = value.rawValue
            await saveWordToFirebase(updatedWord)
            AnalyticsService.shared.logEvent(.partOfSpeechChanged)
        }
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
            var updatedWord = word
            updatedWord.examples = examples
            await saveWordToFirebase(updatedWord)
        }
    }

    // MARK: - Collaborative Features Methods

    private func toggleLike() {
        Task {
            do {
                try await dictionaryService.toggleLike(for: word.id, in: dictionaryId)
            } catch {
                errorReceived(error)
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
            } catch {
                errorReceived(title: "Delete failed", error)
            }
        }
    }

    private func errorReceived(title: String, _ error: Error) {
        AlertCenter.shared.showAlert(
            with: .info(
                title: title,
                message: error.localizedDescription
            )
        )
    }
}

// MARK: - StatSummaryCard

extension SharedWordDetailsView {
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
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .clippedWithPaddingAndBackground(Color.tertiarySystemGroupedBackground, cornerRadius: 16)
        }
    }
}
