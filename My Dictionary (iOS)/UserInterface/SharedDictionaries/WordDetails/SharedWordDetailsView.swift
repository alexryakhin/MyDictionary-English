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
            title: Loc.Navigation.wordDetails.localized,
            mode: .inline,
            showsBackButton: true,
            trailingContent: {
                if canEdit {
                    HeaderButton(icon: "trash", color: .red) {
                        showDeleteAlert()
                    }
                }
                HeaderButton(
                    word.likeCount.formatted(),
                    icon: word.isLikedBy(authenticationService.userEmail ?? "") ? "heart.fill" : "heart",
                    action: toggleLike
                )
            },
            bottomContent: {
                Text(word.wordItself)
                    .font(.largeTitle)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .multilineTextAlignment(.leading)
                    .bold()
            }
        )
        .alert(Loc.WordDetails.editExample.localized, isPresented: .constant(editingExampleIndex != nil), presenting: editingExampleIndex) { index in
            TextField(Loc.App.example.localized, text: $exampleTextFieldStr)
            Button(Loc.Actions.cancel.localized, role: .cancel) {
                AnalyticsService.shared.logEvent(.wordExampleChangingCanceled)
            }
            Button(Loc.Actions.save.localized) {
                updateExample(at: index, text: exampleTextFieldStr)
                editingExampleIndex = nil
                exampleTextFieldStr = .empty
                AnalyticsService.shared.logEvent(.wordExampleChanged)
            }
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
        CustomSectionView(header: Loc.App.transcription.localized, headerFontStyle: .stealth) {
            if canEdit {
                TextField(Loc.App.transcription.localized, text: $phoneticText, axis: .vertical)
                    .focused($isPhoneticsFocused)
                    .fontWeight(.semibold)
            } else {
                Text(phoneticText.nilIfEmpty ?? Loc.Words.noTranscription.localized)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fontWeight(.semibold)
            }
        } trailingContent: {
            if isPhoneticsFocused {
                HeaderButton(Loc.Actions.done.localized, size: .small) {
                    isPhoneticsFocused = false
                    savePhonetic()
                }
            } else {
                HeaderButton(Loc.Actions.listen.localized, icon: "speaker.wave.2.fill", size: .small) {
                    play(word.wordItself, isWord: true)
                }
            }
        }
    }

    private var partOfSpeechSectionView: some View {
        CustomSectionView(header: Loc.App.partOfSpeech.localized, headerFontStyle: .stealth) {
            Text(PartOfSpeech(rawValue: word.partOfSpeech).displayName)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity, alignment: .leading)
        } trailingContent: {
            if canEdit {
                HeaderButtonMenu(Loc.Actions.edit.localized, size: .small) {
                    ForEach(PartOfSpeech.allCases, id: \.self) { partCase in
                        Button {
                            updatePartOfSpeech(partCase)
                        } label: {
                            Text(partCase.displayName)
                        }
                    }
                }
            }
        }
    }

    private var definitionSectionView: some View {
        CustomSectionView(header: Loc.App.definition.localized, headerFontStyle: .stealth) {
            if canEdit {
                TextField(Loc.App.definition.localized, text: $definitionText, axis: .vertical)
                    .focused($isDefinitionFocused)
                    .fontWeight(.semibold)
            } else {
                Text(definitionText.nilIfEmpty ?? Loc.Words.noDefinition.localized)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fontWeight(.semibold)
            }
        } trailingContent: {
            if isDefinitionFocused {
                HeaderButton(Loc.Actions.done.localized, size: .small) {
                    isDefinitionFocused = false
                    saveDefinition()
                    AnalyticsService.shared.logEvent(.wordDefinitionChanged)
                }
            } else {
                HeaderButton(Loc.Actions.listen.localized, icon: "speaker.wave.2.fill", size: .small) {
                    play(word.definition)
                    AnalyticsService.shared.logEvent(.wordDefinitionPlayed)
                }
            }
        }
    }

    @ViewBuilder
    private var languageSectionView: some View {
        if word.shouldShowLanguageLabel {
            CustomSectionView(header: Loc.App.language.localized, headerFontStyle: .stealth) {
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
            header: Loc.Words.examples.localized,
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
                                    Label(Loc.Actions.listen.localized, systemImage: "speaker.wave.2.fill")
                                }
                                if canEdit {
                                    Button {
                                        exampleTextFieldStr = example
                                        editingExampleIndex = index
                                        AnalyticsService.shared.logEvent(.wordExampleChangeButtonTapped)
                                    } label: {
                                        Label(Loc.Actions.edit.localized, systemImage: "pencil")
                                    }
                                    Section {
                                        Button(role: .destructive) {
                                            removeExample(at: index)
                                            AnalyticsService.shared.logEvent(.wordExampleRemoved)
                                        } label: {
                                            Label(Loc.Actions.delete.localized, systemImage: "trash")
                                        }
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
                Text(Loc.Words.noExamplesYet.localized)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
            }

            if isAddingExample {
                InputView(
                    Loc.Words.typeExampleHere.localized,
                    submitLabel: .done,
                    text: $exampleTextFieldStr,
                    onSubmit: {
                        addExample(exampleTextFieldStr)
                        isAddingExample = false
                        exampleTextFieldStr = .empty
                        AnalyticsService.shared.logEvent(.wordExampleAdded)
                    },
                    trailingButtonLabel: Loc.Actions.cancel.localized
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
                    HeaderButton(Loc.Actions.save.localized, icon: "checkmark", size: .small) {
                        addExample(exampleTextFieldStr)
                        isAddingExample = false
                        exampleTextFieldStr = .empty
                        AnalyticsService.shared.logEvent(.wordExampleAdded)
                    }
                } else {
                    HeaderButton(Loc.Words.addExample.localized, icon: "plus", size: .small) {
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
            header: Loc.SharedDictionaries.collaborativeFeatures.localized,
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
                title: Loc.SharedDictionaries.yourScore.localized,
                value: userScore.formatted(),
                icon: "trophy.fill"
            )

            StatSummaryCard(
                title: Loc.SharedDictionaries.yourStatus.localized,
                value: userDifficulty.displayName,
                icon: userDifficulty.imageName
            )
        }
    }

    private var statsSummary: some View {
        HStack(spacing: 12) {
            StatSummaryCard(
                title: Loc.SharedDictionaries.averageScore.localized,
                value: word.averageDifficulty.formatted(),
                icon: "chart.bar.fill"
            )

            StatSummaryCard(
                title: Loc.Analytics.totalRatings.localized,
                value: word.difficulties.count.formatted(),
                icon: "person.2.fill"
            )
        }
    }

    private var viewStatsButton: some View {
        ActionButton(
            Loc.Analytics.viewDetailedStatistics.localized,
            systemImage: "chart.bar.doc.horizontal"
        ) {
            NavigationManager.shared.navigationPath.append(
                NavigationDestination.sharedWordDifficultyStats(
                    word: word
                )
            )
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

            HapticManager.shared.triggerNotification(type: .success)
        } catch {
            errorReceived(title: Loc.Errors.updateFailed.localized, error)
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
                title: Loc.Words.deleteWord.localized,
                message: Loc.Words.deleteWordConfirmation.localized,
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
                HapticManager.shared.triggerNotification(type: .success)
            } catch {
                errorReceived(title: Loc.Errors.deleteFailed.localized, error)
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
