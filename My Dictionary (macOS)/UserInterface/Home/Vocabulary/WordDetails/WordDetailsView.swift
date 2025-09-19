import SwiftUI
import Combine
import Flow

struct WordDetailsView: View {

    @StateObject var word: CDWord
    @Environment(\.dismiss) private var dismiss
    @StateObject private var ttsPlayer = TTSPlayer.shared

    @FocusState private var isPhoneticsFocused: Bool
    @FocusState private var isDefinitionFocused: Bool
    @FocusState private var isNotesFocused: Bool
    @State private var showingTagSelection = false
    @State private var showingAddToSharedDictionary = false
    @State private var showingMeaningsList = false
    @State private var meaningToEdit: CDMeaning?

    init(word: CDWord) {
        self._word = StateObject(wrappedValue: word)
    }

    var body: some View {
        ScrollViewWithCustomNavBar {
            LazyVStack(spacing: 8) {
                transcriptionSectionView
                partOfSpeechSectionView
                meaningsSectionView
                notesSectionView
                difficultySectionView
                languageSectionView
                tagsSectionView
            }
            .padding(12)
            .animation(.default, value: word)
        } navigationBar: {
            Text(word.wordItself ?? "")
                .font(.largeTitle)
                .frame(maxWidth: .infinity, alignment: .leading)
                .multilineTextAlignment(.leading)
                .bold()
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .padding(.top, 16)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .groupedBackground()
        .navigationTitle(Loc.Navigation.wordDetails)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                // Shared Dictionaries button
                if AuthenticationService.shared.isSignedIn {
                    Button {
                        showingAddToSharedDictionary = true
                    } label: {
                        Image(systemName: "person.2.badge.plus")
                    }
                    .help(Loc.Words.addToSharedDictionary)
                    .hideIfOffline()
                    
                }

                // Favorite button
                Button {
                    word.isFavorite.toggle()
                    saveContext()
                    AnalyticsService.shared.logEvent(.wordFavoriteTapped)
                } label: {
                    Image(systemName: word.isFavorite ? "heart.fill" : "heart")
                        .foregroundStyle(word.isFavorite ? .red : .primary)
                }
                .help(Loc.Actions.toggleFavorite)

                // Delete button
                Button {
                    showDeleteAlert()
                } label: {
                    Image(systemName: "trash")
                        .foregroundStyle(.red)
                }
                .help(Loc.Words.deleteWord)
            }
        }
        .sheet(isPresented: $showingTagSelection) {
            WordTagSelectionView(word: word)
        }
        .sheet(isPresented: $showingAddToSharedDictionary) {
            AddExistingWordToSharedView(word: word)
        }
        .sheet(isPresented: $showingMeaningsList) {
            MeaningsListView(word: word)
        }
        .sheet(item: $meaningToEdit) { meaning in
            MeaningEditView(meaning: meaning)
        }
    }

    private var transcriptionSectionView: some View {
        CustomSectionView(
            header: Loc.Words.transcription,
            headerFontStyle: .stealth
        ) {
            TextField(
                Loc.Words.transcription,
                text: Binding(
                    get: { word.phonetic ?? "" },
                    set: { word.phonetic = $0 }
                ),
                axis: .vertical
            )
            .textFieldStyle(.plain)
            .focused($isPhoneticsFocused)
            .fontWeight(.semibold)
        } trailingContent: {
            if isPhoneticsFocused {
                HeaderButton(Loc.Actions.done, size: .small) {
                    isPhoneticsFocused = false
                    saveContext()
                }
            } else {
                AsyncHeaderButton(
                    Loc.Actions.listen,
                    icon: "speaker.wave.2.fill",
                    size: .small
                ) {
                    try await play(word.wordItself, isWord: true)
                }
                .disabled(ttsPlayer.isPlaying)
            }
        }
    }

    private var partOfSpeechSectionView: some View {
        CustomSectionView(
            header: Loc.Words.partOfSpeech,
            headerFontStyle: .stealth
        ) {
            Text(PartOfSpeech(rawValue: word.partOfSpeech).displayName)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity, alignment: .leading)
        } trailingContent: {
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

    private var meaningsSectionView: some View {
        let meanings = word.meaningsArray
        let showLimited = meanings.count > 3
        let displayMeanings = showLimited ? Array(meanings.prefix(3)) : meanings
        
        return CustomSectionView(
            header: meanings.count > 1 ? "\(Loc.Words.meanings) (\(meanings.count))" : Loc.Words.meaning,
            headerFontStyle: .stealth,
            hPadding: .zero
        ) {
            if meanings.isEmpty {
                // Fallback to legacy definition if no meanings exist
                TextField(
                    Loc.Words.WordDetails.definition,
                    text: Binding(
                        get: { word.definition ?? "" },
                        set: { word.definition = $0 }
                    ),
                    axis: .vertical
                )
                .textFieldStyle(.plain)
                .focused($isDefinitionFocused)
                .fontWeight(.semibold)
                .padding(vertical: 12, horizontal: 16)
            } else {
                FormWithDivider {
                    ForEach(Array(displayMeanings.enumerated()), id: \.element.id) { index, meaning in
                        meaningRowView(meaning: meaning, index: index + 1)
                    }
                }
                
                if showLimited {
                    HeaderButton(
                        "\(Loc.Words.showAllMeanings) (\(meanings.count))",
                        icon: "list.number",
                        size: .small
                    ) {
                        showingMeaningsList = true
                    }
                    .padding(.top, 8)
                    .padding(.horizontal, 16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        } trailingContent: {
            if meanings.isEmpty {
                // Legacy definition controls
                if isDefinitionFocused {
                    HeaderButton(Loc.Actions.done, size: .small) {
                        isDefinitionFocused = false
                        AnalyticsService.shared.logEvent(.wordDefinitionChanged)
                        saveContext()
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
                    .disabled(ttsPlayer.isPlaying)
                }
            } else {
                HeaderButton(icon: "plus", size: .small) {
                    addNewMeaning()
                }
            }
        }
    }

    private var notesSectionView: some View {
        CustomSectionView(
            header: Loc.Words.notes,
            headerFontStyle: .stealth
        ) {
            TextField(
                Loc.Words.addNotes,
                text: Binding(
                    get: { word.notes ?? "" },
                    set: { word.notes = $0 }
                ),
                axis: .vertical
            )
            .textFieldStyle(.plain)
            .focused($isNotesFocused)
            .fontWeight(.semibold)
        } trailingContent: {
            if isNotesFocused {
                HeaderButton(Loc.Actions.done, size: .small) {
                    isNotesFocused = false
                    saveContext()
                }
            }
        }
    }

    private var difficultySectionView: some View {
        CustomSectionView(
            header: Loc.Words.difficulty,
            headerFontStyle: .stealth
        ) {
            let difficulty = word.difficultyLevel
            VStack(alignment: .leading, spacing: 4) {
                Label(difficulty.displayName, systemImage: difficulty.imageName)
                    .foregroundStyle(difficulty.color)
                    .fontWeight(.semibold)

                Text("\(Loc.Words.score): \(word.difficultyScore)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } trailingContent: {
            // Show info that difficulty can only be changed through quizzes
            Text(Loc.Words.quizBased)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var languageSectionView: some View {
        CustomSectionView(
            header: Loc.Words.language,
            headerFontStyle: .stealth
        ) {
            HStack {
                Text(word.languageDisplayName)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if let languageCode = word.languageCode {
                    TagView(text: languageCode.uppercased(), color: .blue, size: .mini)
                }
            }
        } trailingContent: {
            HeaderButtonMenu(Loc.Actions.edit, size: .small) {
                ForEach(InputLanguage.allCasesSorted, id: \.self) { lang in
                    Button {
                        updateLanguage(lang)
                    } label: {
                        Text(lang.displayName)
                    }
                }
            }
        }
    }

    private var tagsSectionView: some View {
        CustomSectionView(
            header: Loc.Words.tags,
            headerFontStyle: .stealth
        ) {
            if word.tagsArray.isEmpty {
                Text(Loc.Words.noTagsAddedYet)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                HFlow(alignment: .top, spacing: 8) {
                    ForEach(word.tagsArray) { tag in
                        HeaderButton(
                            tag.name.orEmpty,
                            color: tag.colorValue.color,
                            size: .small,
                            style: .borderedProminent,
                            action: {}
                        )
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        } trailingContent: {
            HeaderButton(Loc.Tags.addTag, icon: "plus", size: .small) {
                showingTagSelection = true
            }
        }
    }



    // MARK: - Private Methods
    
    @ViewBuilder
    private func meaningRowView(meaning: CDMeaning, index: Int) -> some View {
        let definition = meaning.definition ?? Loc.Words.WordDetails.definition

        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text("\(index).")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(definition)
                    .fontWeight(.semibold)
                
                Spacer()

                Menu {
                    Button {
                        Task {
                            try await play(definition)
                        }
                        AnalyticsService.shared.logEvent(.meaningPlayed)
                    } label: {
                        Label(Loc.Actions.listen, systemImage: "speaker.wave.2.fill")
                    }
                    .disabled(ttsPlayer.isPlaying)
                    Button {
                        meaningToEdit = meaning
                        AnalyticsService.shared.logEvent(.wordExampleChangeButtonTapped)
                    } label: {
                        Label(Loc.Actions.edit, systemImage: "pencil")
                    }
                    Section {
                        Button(role: .destructive) {
                            deleteMeaning(meaning)
                            AnalyticsService.shared.logEvent(.wordExampleRemoved)
                        } label: {
                            Label(Loc.Actions.delete, systemImage: "trash")
                                .tint(.red)
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundStyle(.secondary)
                        .padding(6)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            
            // Show examples for this meaning
            let examples = meaning.examplesDecoded
            if !examples.isEmpty {
                ForEach(Array(examples.enumerated()), id: \.offset) { _, example in
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
        .padding(vertical: 12, horizontal: 16)
    }
    
    private func showAllMeanings() {
        // TODO: Navigate to full meanings list view
        // This could be a sheet or navigation to a dedicated view
    }
    
    private func addNewMeaning() {
        do {
            let _ = try word.addMeaning(definition: Loc.Words.newDefinition, examples: [])
            saveContext()
        } catch {
            errorReceived(error)
        }
    }

    private func saveContext() {
        Task {
            word.isSynced = false
            word.updatedAt = Date()

            do {
                try CoreDataService.shared.saveContext()
            } catch {
                errorReceived(error)
            }
        }
    }

    private func play(
        _ text: String?,
        isWord: Bool = false
    ) async throws {
        guard let text else { return }
        try await ttsPlayer.play(
            text,
            languageCode: isWord ? word.languageCode : nil
        )
    }

    private func updatePartOfSpeech(_ value: PartOfSpeech) {
        word.partOfSpeech = value.rawValue
        saveContext()
        AnalyticsService.shared.logEvent(.partOfSpeechChanged)
    }

    private func updateLanguage(_ value: InputLanguage) {
        word.languageCode = value.rawValue
        saveContext()
        AnalyticsService.shared.logEvent(.wordLanguageCodeChanged)
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
        guard let id = word.id?.uuidString else { return }

        do {
            try WordsProvider.shared.delete(with: id)
        } catch {
            errorReceived(title: "Delete failed", error)
        }
    }

    private func removeTag(_ tag: CDTag) {
        try? TagService.shared.removeTagFromWord(tag, word: word)
        saveContext()
        AnalyticsService.shared.logEvent(.tagRemovedFromWord)
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
}
