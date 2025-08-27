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

    // Mutable state for editable fields
    @State private var phoneticText: String = ""
    @State private var definitionText: String = ""

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
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                transcriptionSectionView
                partOfSpeechSectionView
                meaningsSectionView
                languageSectionView
                collaborativeFeaturesSection
            }
            .padding(.horizontal, 16)
            .animation(.default, value: word)
            .if(isPad) { view in
                view
                    .frame(maxWidth: 550, alignment: .center)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .groupedBackground()
        .navigation(
            title: Loc.Navigation.wordDetails,
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
                }
            }
        }
        .onDisappear {
            // Stop the real-time listener when leaving the view
            dictionaryService.stopSharedWordListener(dictionaryId: dictionaryId, wordId: word.id)
        }
    }

    private var transcriptionSectionView: some View {
        CustomSectionView(header: Loc.Words.transcription, headerFontStyle: .stealth) {
            if canEdit {
                TextField(Loc.Words.transcription, text: $phoneticText, axis: .vertical)
                    .focused($isPhoneticsFocused)
                    .fontWeight(.semibold)
            } else {
                Text(phoneticText.nilIfEmpty ?? Loc.Words.noTranscription)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fontWeight(.semibold)
            }
        } trailingContent: {
            if isPhoneticsFocused {
                HeaderButton(Loc.Actions.done, size: .small) {
                    isPhoneticsFocused = false
                    savePhonetic()
                }
            } else {
                AsyncHeaderButton(
                    Loc.Actions.listen,
                    icon: "speaker.wave.2.fill",
                    size: .small
                ) {
                    try await play(word.wordItself, isWord: true)
                }
                .disabled(TTSPlayer.shared.isPlaying)
            }
        }
    }

    private var partOfSpeechSectionView: some View {
        CustomSectionView(header: Loc.Words.partOfSpeech, headerFontStyle: .stealth) {
            Text(PartOfSpeech(rawValue: word.partOfSpeech).displayName)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity, alignment: .leading)
        } trailingContent: {
            if canEdit {
                HeaderButtonMenu(Loc.Actions.edit, size: .small) {
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

    private var meaningsSectionView: some View {
        let meanings = word.meanings
        let showLimited = meanings.count > 3
        let displayMeanings = showLimited ? Array(meanings.prefix(3)) : meanings
        
        return CustomSectionView(header: meanings.count > 1 ? "Meanings (\(meanings.count))" : "Meaning", headerFontStyle: .stealth) {
            if meanings.isEmpty {
                // Fallback to legacy definition if no meanings exist
                if canEdit {
                    TextField(Loc.Words.definition, text: $definitionText, axis: .vertical)
                        .focused($isDefinitionFocused)
                        .fontWeight(.semibold)
                } else {
                    Text(definitionText.nilIfEmpty ?? Loc.Words.noDefinition)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .fontWeight(.semibold)
                }
            } else {
                FormWithDivider {
                    ForEach(Array(displayMeanings.enumerated()), id: \.element.id) { index, meaning in
                        meaningRowView(meaning: meaning, index: index + 1)
                    }
                }
                
                if showLimited {
                    HeaderButton(
                        "Show all \(meanings.count) meanings",
                        icon: "list.number",
                        size: .small
                    ) {
                        NavigationManager.shared.navigate(to: .sharedWordMeaningsList(word, dictionaryId: dictionaryId))
                    }
                    .padding(.top, 8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        } trailingContent: {
            if meanings.isEmpty {
                // Legacy definition controls
                if isDefinitionFocused {
                    HeaderButton(Loc.Actions.done, size: .small) {
                        isDefinitionFocused = false
                        saveDefinition()
                        AnalyticsService.shared.logEvent(.wordDefinitionChanged)
                    }
                } else {
                    AsyncHeaderButton(
                        Loc.Actions.listen,
                        icon: "speaker.wave.2.fill",
                        size: .small
                    ) {
                        try await play(word.definition)
                        AnalyticsService.shared.logEvent(.wordDefinitionPlayed)
                    }
                    .disabled(TTSPlayer.shared.isPlaying)
                }
            } else {
                if canEdit {
                    HeaderButton(icon: "plus", size: .small) {
                        addNewMeaning()
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var languageSectionView: some View {
        if word.shouldShowLanguageLabel {
            CustomSectionView(header: Loc.Words.language, headerFontStyle: .stealth) {
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

    private func meaningRowView(meaning: SharedWordMeaning, index: Int) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("\(index).")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(meaning.definition)
                    .fontWeight(.semibold)
                
                Spacer()
                
                AsyncHeaderButton(
                    icon: "speaker.wave.2.fill",
                    size: .small
                ) {
                    try await play(meaning.definition)
                    AnalyticsService.shared.logEvent(.wordDefinitionPlayed)
                }
                .disabled(TTSPlayer.shared.isPlaying)
            }
            
            // Show examples for this meaning
            if !meaning.examples.isEmpty {
                ForEach(meaning.examples, id: \.self) { example in
                    HStack {
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
                            AnalyticsService.shared.logEvent(.wordExamplePlayed)
                        }
                        .disabled(TTSPlayer.shared.isPlaying)
                    }
                    .padding(.leading, 20)
                }
            }
        }
        .padding(.vertical, 8)
    }

    // MARK: - Collaborative Features Section

    private var collaborativeFeaturesSection: some View {
        CustomSectionView(
            header: Loc.SharedDictionaries.collaborativeFeatures,
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
                title: Loc.SharedDictionaries.yourScore,
                value: userScore.formatted(),
                icon: "trophy.fill"
            )

            StatSummaryCard(
                title: Loc.SharedDictionaries.yourStatus,
                value: userDifficulty.displayName,
                icon: userDifficulty.imageName
            )
        }
    }

    private var statsSummary: some View {
        HStack(spacing: 12) {
            StatSummaryCard(
                title: Loc.SharedDictionaries.averageScore,
                value: word.averageDifficulty.formatted(),
                icon: "chart.bar.fill"
            )

            StatSummaryCard(
                title: Loc.Analytics.totalRatings,
                value: word.difficulties.count.formatted(),
                icon: "person.2.fill"
            )
        }
    }

    private var viewStatsButton: some View {
        ActionButton(
            Loc.Analytics.viewDetailedStatistics,
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
            // Update the primary meaning's definition
            if var primaryMeaning = updatedWord.primaryMeaning {
                primaryMeaning.definition = definitionText
                var meanings = updatedWord.meanings
                if let index = meanings.firstIndex(where: { $0.id == primaryMeaning.id }) {
                    meanings[index] = primaryMeaning
                    updatedWord = SharedWord(
                        id: updatedWord.id,
                        wordItself: updatedWord.wordItself,
                        meanings: meanings,
                        partOfSpeech: updatedWord.partOfSpeech,
                        phonetic: updatedWord.phonetic,
                        languageCode: updatedWord.languageCode,
                        timestamp: updatedWord.timestamp,
                        updatedAt: Date(),
                        addedByEmail: updatedWord.addedByEmail,
                        addedByDisplayName: updatedWord.addedByDisplayName,
                        addedAt: updatedWord.addedAt,
                        likes: updatedWord.likes,
                        difficulties: updatedWord.difficulties
                    )
                }
            }
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
            errorReceived(title: Loc.Errors.updateFailed, error)
        }
    }

    private func play(_ text: String?, isWord: Bool = false) async throws {
        guard let text else { return }
        try await TTSPlayer.shared.play(
            text,
            targetLanguage: isWord
            ? word.languageCode
            : Locale.current.language.languageCode?.identifier
        )
    }

    private func updatePartOfSpeech(_ value: PartOfSpeech) {
        Task {
            var updatedWord = word
            updatedWord.partOfSpeech = value.rawValue
            await saveWordToFirebase(updatedWord)
            AnalyticsService.shared.logEvent(.partOfSpeechChanged)
        }
    }


    
    private func addNewMeaning() {
        // Create a new meaning and add it to the word
        let newMeaning = SharedWordMeaning(
            definition: "New definition",
            examples: [],
            order: word.meanings.count
        )
        
        var updatedWord = word
        updatedWord.meanings.append(newMeaning)
        
        Task {
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
                title: Loc.Words.deleteWord,
                message: Loc.Words.deleteWordConfirmation,
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
                errorReceived(title: Loc.Errors.deleteFailed, error)
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
