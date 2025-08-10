import SwiftUI
import Combine
import Flow

struct WordDetailsContentView: View {

    struct Config: Hashable {
        let id = UUID()
        let word: CDWord
        let dictionary: SharedDictionary?
    }

    @StateObject var word: CDWord
    @Environment(\.dismiss) private var dismiss
    
    // Optional dictionary parameter for shared words
    let dictionary: SharedDictionary?

    @FocusState private var isPhoneticsFocused: Bool
    @FocusState private var isDefinitionFocused: Bool
    @FocusState private var isAddExampleFocused: Bool
    @State private var isAddingExample = false
    @State private var editingExampleIndex: Int?
    @State private var exampleTextFieldStr = ""
    @State private var showingTagSelection = false
    @State private var showingDifficultyPicker = false
    @State private var selectedDifficulty: Difficulty = .new
    @StateObject private var dictionaryService = DictionaryService.shared
    @StateObject private var authenticationService = AuthenticationService.shared
    @StateObject private var tagService = TagService.shared

    init(config: Config) {
        self._word = StateObject(wrappedValue: config.word)
        self.dictionary = config.dictionary
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
            .padding(vertical: 12, horizontal: 16)
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
            TextField("Transcription", text: Binding(
                get: { word.phonetic ?? "" },
                set: { word.phonetic = $0 }
            ), axis: .vertical)
                .focused($isPhoneticsFocused)
                .fontWeight(.semibold)
        } trailingContent: {
            if isPhoneticsFocused {
                HeaderButton(text: "Done") {
                    isPhoneticsFocused = false
                    saveContext()
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
            Text(word.partOfSpeech ?? "")
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
            TextField("Definition", text: Binding(
                get: { word.definition ?? "" },
                set: { word.definition = $0 }
            ), axis: .vertical)
                .focused($isDefinitionFocused)
                .fontWeight(.semibold)
        } trailingContent: {
            if isDefinitionFocused {
                HeaderButton(text: "Done") {
                    isDefinitionFocused = false
                    AnalyticsService.shared.logEvent(.wordDefinitionChanged)
                    saveContext()
                }
            } else {
                HeaderButton(text: "Listen", icon: "speaker.wave.2.fill") {
                    play(word.definition)
                    AnalyticsService.shared.logEvent(.wordDefinitionPlayed)
                }
            }
        }
    }

    private var difficultySectionView: some View {
        CustomSectionView(header: "Difficulty", headerFontStyle: .stealth) {
            let difficulty = getCurrentDifficulty()
            Label(difficulty.displayName, systemImage: difficulty.imageName)
                .frame(maxWidth: .infinity, alignment: .leading)
                .foregroundStyle(difficulty.color)
                .fontWeight(.semibold)
        } trailingContent: {
            HeaderButton(text: "Change", style: .bordered) {
                selectedDifficulty = getCurrentDifficulty()
                showingDifficultyPicker = true
            }
            .tint(.blue)
        }
        .sheet(isPresented: $showingDifficultyPicker) {
            difficultyPickerView
        }
    }

    @ViewBuilder
    private var languageSectionView: some View {
        if word.shouldShowLanguageLabel {
            CustomSectionView(header: "Language", headerFontStyle: .stealth) {
                HStack {
                    Text(word.languageDisplayName)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    if let languageCode = word.languageCode {
                        Text(languageCode.uppercased())
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
    }
    
    private var difficultyPickerView: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(Difficulty.allCases, id: \.self) { difficulty in
                    Button {
                        withAnimation {
                            selectedDifficulty = difficulty
                        }
                    } label: {
                        HStack {
                            Label(difficulty.displayName, systemImage: difficulty.imageName)
                                .foregroundStyle(selectedDifficulty == difficulty ? .white : difficulty.color)

                            Spacer()

                            if selectedDifficulty == difficulty {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.white)
                            }
                        }
                        .clippedWithPaddingAndBackground(
                            selectedDifficulty == difficulty
                            ? difficulty.color
                            : difficulty.color.opacity(0.2)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
        .groupedBackground()
        .navigation(title: "Select Difficulty Level", mode: .inline, trailingContent: {
            HeaderButton(text: "Save", style: .borderedProminent, font: .body) {
                updateDifficulty()
                showingDifficultyPicker = false
            }
            .bold()
        })
        .presentationDetents([.medium])
    }
    
    private func updateDifficulty() {
        word.difficultyLevel = selectedDifficulty.level
        
        do {
            try CoreDataService.shared.saveContext()
            AnalyticsService.shared.logEvent(.wordDifficultyChanged)
        } catch {
            print("❌ Failed to update word difficulty: \(error)")
        }
    }
    
    private func getCurrentDifficulty() -> Difficulty {
        switch word.difficultyLevel {
        case 0:
            return .new
        case 1:
            return .inProgress
        case 2:
            return .needsReview
        case 3:
            return .mastered
        default:
            return .new
        }
    }

    private var tagsSectionView: some View {
        CustomSectionView(header: "Tags", headerFontStyle: .stealth) {
            if word.tagsArray.isEmpty {
                Text("No tags added yet.")
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                HFlow(alignment: .top, spacing: 8) {
                    ForEach(word.tagsArray) { tag in
                        HeaderButton(
                            text: tag.name.orEmpty,
                            style: .borderedProminent,
                            action: {}
                        )
                        .tint(tag.colorValue.color)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        } trailingContent: {
            HeaderButton(text: "Add Tag", icon: "plus") {
                showingTagSelection = true
            }
        }
    }

    private var examplesSectionView: some View {
        CustomSectionView(
            header: "Examples",
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

    // MARK: - Private Methods

    private func saveContext() {
        Task {
            word.isSynced = false
            word.updatedAt = Date()

            do {
                try CoreDataService.shared.saveContext()
                if word.isSharedWord, let dictionary = dictionary {
                    // Sync shared word to shared dictionary
                    if let wordModel = Word(from: word) {
                        try await dictionaryService.updateWordInSharedDictionary(
                            dictionaryId: dictionary.id,
                            word: wordModel
                        )
                    }
                } else if let userId = authenticationService.userId {
                    try await DataSyncService.shared.syncWordToFirestore(
                        word: word,
                        userId: userId
                    )
                }
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
                // Handle error if needed
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
        guard let id = word.id?.uuidString else { return }
        
        Task { @MainActor in
            if word.isSharedWord, let dictionary = dictionary {
                // Delete from shared dictionary
                do {
                    try await dictionaryService.deleteWordFromSharedDictionary(
                        dictionaryId: dictionary.id,
                        wordId: id
                    )
                    print("✅ [WordDetails] Shared word deleted successfully")
                    HapticManager.shared.triggerNotification(type: .success)
                } catch {
                    print("❌ [WordDetails] Failed to delete shared word: \(error.localizedDescription)")
                    errorReceived(title: "Delete failed", error)
                }
            } else {
                // Delete private word
                try? WordsProvider.shared.deleteWord(with: id)
            }
        }
    }

    private func removeTag(_ tag: CDTag) {
        try? TagService.shared.removeTagFromWord(tag, word: word)
        saveContext()
        AnalyticsService.shared.logEvent(.tagRemovedFromWord)
    }
}

struct TagView: View {
    let tag: CDTag
    
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(tag.colorValue.color)
                .frame(width: 12, height: 12)
            
            Text(tag.name ?? "")
                .font(.body)
                .fontWeight(.medium)
            
            Spacer()
            
            Image(systemName: "xmark")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(tag.colorValue.color.opacity(0.2))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
