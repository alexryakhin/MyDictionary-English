import SwiftUI
import Combine
import Flow

struct WordDetailsContentView: View {

    @StateObject var word: CDWord
    @Environment(\.dismiss) private var dismiss

    @FocusState private var isPhoneticsFocused: Bool
    @FocusState private var isDefinitionFocused: Bool
    @FocusState private var isAddExampleFocused: Bool
    @State private var isAddingExample = false
    @State private var editingExampleIndex: Int?
    @State private var exampleTextFieldStr = ""
    @State private var showingTagSelection = false

    init(word: CDWord) {
        self._word = StateObject(wrappedValue: word)
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                transcriptionSectionView
                partOfSpeechSectionView
                definitionSectionView
                difficultySectionView
                languageSectionView
                tagsSectionView
                examplesSectionView
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
                HeaderButton(icon: "trash", color: .red) {
                    showDeleteAlert()
                }
                HeaderButton(icon: word.isFavorite ? "heart.fill" : "heart") {
                    word.isFavorite.toggle()
                    saveContext()
                    AnalyticsService.shared.logEvent(.wordFavoriteTapped)
                }
                .animation(.easeInOut(duration: 0.2), value: word.isFavorite)
            },
            bottomContent: {
                Text(word.wordItself ?? "")
                    .font(.largeTitle)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .multilineTextAlignment(.leading)
                    .bold()
            }
        )
        .sheet(isPresented: $showingTagSelection) {
            WordTagSelectionView(word: word)
        }
        .alert(Loc.Words.WordDetails.editExample, isPresented: .constant(editingExampleIndex != nil), presenting: editingExampleIndex) { index in
            TextField(Loc.Words.WordDetails.example, text: $exampleTextFieldStr)
            Button(Loc.Actions.cancel, role: .cancel) {
                AnalyticsService.shared.logEvent(.wordExampleChangingCanceled)
            }
            Button(Loc.Actions.save) {
                updateExample(at: index, text: exampleTextFieldStr)
                editingExampleIndex = nil
                exampleTextFieldStr = .empty
                AnalyticsService.shared.logEvent(.wordExampleChanged)
            }
        }
    }

    private var transcriptionSectionView: some View {
        CustomSectionView(header: Loc.Words.WordDetails.transcription, headerFontStyle: .stealth) {
            TextField(Loc.Words.WordDetails.transcription, text: Binding(
                get: { word.phonetic ?? "" },
                set: { word.phonetic = $0 }
            ), axis: .vertical)
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
                .disabled(TTSPlayer.shared.isPlaying)
            }
        }
    }

    private var partOfSpeechSectionView: some View {
        CustomSectionView(header: Loc.Words.WordDetails.partOfSpeech, headerFontStyle: .stealth) {
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

    private var definitionSectionView: some View {
        CustomSectionView(header: Loc.Words.WordDetails.definition, headerFontStyle: .stealth) {
            TextField(Loc.Words.WordDetails.definition, text: Binding(
                get: { word.definition ?? "" },
                set: { word.definition = $0 }
            ), axis: .vertical)
            .focused($isDefinitionFocused)
            .fontWeight(.semibold)
        } trailingContent: {
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
                .disabled(TTSPlayer.shared.isPlaying)
            }
        }
    }

    private var difficultySectionView: some View {
        CustomSectionView(header: Loc.Words.WordDetails.difficulty, headerFontStyle: .stealth) {
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
        if word.shouldShowLanguageLabel {
            CustomSectionView(header: Loc.Words.language, headerFontStyle: .stealth) {
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
        CustomSectionView(header: Loc.Words.tags, headerFontStyle: .stealth) {
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
            HeaderButton(Loc.Words.addTag, icon: "plus", size: .small) {
                showingTagSelection = true
            }
        }
    }

    private var examplesSectionView: some View {
        CustomSectionView(
            header: Loc.Words.WordDetails.examples,
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
                                    Task {
                                        try await play(example)
                                    }
                                    AnalyticsService.shared.logEvent(.wordExamplePlayed)
                                } label: {
                                    Label(Loc.Actions.listen, systemImage: "speaker.wave.2.fill")
                                }
                                .disabled(TTSPlayer.shared.isPlaying)
                                Button {
                                    exampleTextFieldStr = example
                                    editingExampleIndex = index
                                    AnalyticsService.shared.logEvent(.wordExampleChangeButtonTapped)
                                } label: {
                                    Label(Loc.Actions.edit, systemImage: "pencil")
                                }
                                Section {
                                    Button(role: .destructive) {
                                        removeExample(at: index)
                                        AnalyticsService.shared.logEvent(.wordExampleRemoved)
                                    } label: {
                                        Label(Loc.Actions.delete, systemImage: "trash")
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
                Text(Loc.Words.noExamplesYet)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
            }

            if isAddingExample {
                InputView(
                    Loc.Words.WordDetails.typeExampleHere,
                    submitLabel: .done,
                    text: $exampleTextFieldStr,
                    onSubmit: {
                        addExample(exampleTextFieldStr)
                        isAddingExample = false
                        exampleTextFieldStr = .empty
                        AnalyticsService.shared.logEvent(.wordExampleAdded)
                    },
                    trailingButtonLabel: Loc.Actions.cancel
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
                HeaderButton(Loc.Actions.save, icon: "checkmark", size: .small) {
                    addExample(exampleTextFieldStr)
                    isAddingExample = false
                    exampleTextFieldStr = .empty
                    AnalyticsService.shared.logEvent(.wordExampleAdded)
                }
            } else {
                HeaderButton(Loc.Words.WordDetails.addExample, icon: "plus", size: .small) {
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
            try WordsProvider.shared.deleteWord(with: id)
        } catch {
            errorReceived(title: Loc.Words.WordDetails.deleteFailed, error)
        }
    }

    private func removeTag(_ tag: CDTag) {
        try? TagService.shared.removeTagFromWord(tag, word: word)
        saveContext()
        AnalyticsService.shared.logEvent(.tagRemovedFromWord)
    }
}
