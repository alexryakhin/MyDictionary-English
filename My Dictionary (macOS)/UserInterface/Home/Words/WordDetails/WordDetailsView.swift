import SwiftUI
import Combine
import Flow

struct WordDetailsView: View {

    @StateObject var word: CDWord
    @Environment(\.dismiss) private var dismiss

    @FocusState private var isPhoneticsFocused: Bool
    @FocusState private var isDefinitionFocused: Bool
    @FocusState private var isAddExampleFocused: Bool

    @State private var isAddingExample = false
    @State private var editingExampleIndex: Int?
    @State private var exampleTextFieldStr = ""
    @State private var showingTagSelection = false
    @State private var showingAddToSharedDictionary = false

    @StateObject private var dictionaryService = DictionaryService.shared
    @StateObject private var authenticationService = AuthenticationService.shared
    @StateObject private var tagService = TagService.shared

    init(word: CDWord) {
        self._word = StateObject(wrappedValue: word)
    }

    var body: some View {
        ScrollViewWithCustomNavBar {
            LazyVStack(spacing: 8) {
                transcriptionSectionView
                partOfSpeechSectionView
                definitionSectionView
                difficultySectionView
                languageSectionView
                tagsSectionView
                examplesSectionView
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
        .navigationTitle(Loc.Navigation.wordDetails.localized)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                // Shared Dictionaries button
                if AuthenticationService.shared.isSignedIn {
                    Button {
                        showingAddToSharedDictionary = true
                    } label: {
                        Image(systemName: "person.2.badge.plus")
                    }
                    .help(Loc.Words.addToSharedDictionary.localized)
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
                .help(Loc.Actions.toggleFavorite.localized)
                
                // Delete button
                Button {
                    showDeleteAlert()
                } label: {
                    Image(systemName: "trash")
                        .foregroundStyle(.red)
                }
                .help(Loc.Words.deleteWord.localized)
            }
        }
        .sheet(isPresented: $showingTagSelection) {
            WordTagSelectionView(word: word)
        }
        .sheet(isPresented: $showingAddToSharedDictionary) {
            AddExistingWordToSharedView(word: word)
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
    }

    private var transcriptionSectionView: some View {
        CustomSectionView(
            header: Loc.Words.transcription.localized,
            headerFontStyle: .stealth
        ) {
            TextField(
                Loc.Words.transcription.localized,
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
                HeaderButton(Loc.Actions.done.localized, size: .small) {
                    isPhoneticsFocused = false
                    saveContext()
                }
            } else {
                HeaderButton(Loc.Actions.listen.localized, icon: "speaker.wave.2.fill", size: .small) {
                    play(word.wordItself, isWord: true)
                }
            }
        }
    }

    private var partOfSpeechSectionView: some View {
        CustomSectionView(
            header: Loc.Words.partOfSpeech.localized,
            headerFontStyle: .stealth
        ) {
            Text(PartOfSpeech(rawValue: word.partOfSpeech).displayName)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity, alignment: .leading)
        } trailingContent: {
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

    private var definitionSectionView: some View {
        CustomSectionView(
            header: Loc.Words.definition.localized,
            headerFontStyle: .stealth
        ) {
            TextField(
                Loc.Words.definition.localized,
                text: Binding(
                    get: { word.definition ?? "" },
                    set: { word.definition = $0 }
                ),
                axis: .vertical
            )
            .textFieldStyle(.plain)
            .focused($isDefinitionFocused)
            .fontWeight(.semibold)
        } trailingContent: {
            if isDefinitionFocused {
                HeaderButton(Loc.Actions.done.localized, size: .small) {
                    isDefinitionFocused = false
                    AnalyticsService.shared.logEvent(.wordDefinitionChanged)
                    saveContext()
                }
            } else {
                HeaderButton(Loc.Actions.listen.localized, icon: "speaker.wave.2.fill", size: .small) {
                    play(word.definition)
                    AnalyticsService.shared.logEvent(.wordDefinitionPlayed)
                }
            }
        }
    }

    private var difficultySectionView: some View {
        CustomSectionView(
            header: Loc.Words.difficulty.localized,
            headerFontStyle: .stealth
        ) {
            let difficulty = word.difficultyLevel
            VStack(alignment: .leading, spacing: 4) {
                Label(difficulty.displayName, systemImage: difficulty.imageName)
                    .foregroundStyle(difficulty.color)
                    .fontWeight(.semibold)
                
                Text("Score: \(word.difficultyScore)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } trailingContent: {
            // Show info that difficulty can only be changed through quizzes
                            Text(Loc.Words.quizBased.localized)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var languageSectionView: some View {
        if word.shouldShowLanguageLabel {
                    CustomSectionView(
            header: Loc.Words.language.localized,
                headerFontStyle: .stealth
            ) {
                HStack {
                    Text(word.languageDisplayName)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    if let languageCode = word.languageCode {
                        TagView(text: languageCode.uppercased(), color: .blue, size: .mini)
                    }
                }
            }
        }
    }

    private var tagsSectionView: some View {
        CustomSectionView(
            header: Loc.Words.tags.localized,
            headerFontStyle: .stealth
        ) {
            if word.tagsArray.isEmpty {
                Text(Loc.Words.noTagsAddedYet.localized)
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
                            HeaderButton(Loc.Tags.addTag.localized, icon: "plus", size: .small) {
                showingTagSelection = true
            }
        }
    }

    private var examplesSectionView: some View {
        CustomSectionView(
            header: Loc.Words.examples.localized,
            headerFontStyle: .stealth,
            hPadding: 0
        ) {
            if word.examplesDecoded.isNotEmpty {
                FormWithDivider {
                    ForEach(Array(word.examplesDecoded.enumerated()), id: \.offset) { index, example in
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

    // MARK: - Private Methods

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
        word.partOfSpeech = value.rawValue
        saveContext()
        AnalyticsService.shared.logEvent(.partOfSpeechChanged)
    }

    private func addExample(_ example: String) {
        guard !example.isEmpty else { return }
        var currentExamples = word.examplesDecoded
        currentExamples.append(example)
        try? word.updateExamples(currentExamples)
        saveContext()
    }

    private func updateExample(at index: Int, text: String) {
        guard !text.isEmpty else { return }
        var currentExamples = word.examplesDecoded
        currentExamples[index] = text
        try? word.updateExamples(currentExamples)
        saveContext()
    }

    private func removeExample(at index: Int) {
        var currentExamples = word.examplesDecoded
        currentExamples.remove(at: index)
        try? word.updateExamples(currentExamples)
        saveContext()
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
        guard let id = word.id?.uuidString else { return }
        
        do {
            try WordsProvider.shared.deleteWord(with: id)
        } catch {
            errorReceived(title: "Delete failed", error)
        }
    }

    private func removeTag(_ tag: CDTag) {
        try? TagService.shared.removeTagFromWord(tag, word: word)
        saveContext()
        AnalyticsService.shared.logEvent(.tagRemovedFromWord)
    }
}
