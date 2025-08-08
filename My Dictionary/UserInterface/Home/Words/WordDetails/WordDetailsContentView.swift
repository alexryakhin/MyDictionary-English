import SwiftUI
import Combine

struct WordDetailsContentView: View {

    @StateObject var word: CDWord
    @Environment(\.dismiss) private var dismiss
    
    // Optional dictionary parameter for shared words
    let dictionary: DictionaryService.SharedDictionary?

    @FocusState private var isPhoneticsFocused: Bool
    @FocusState private var isDefinitionFocused: Bool
    @FocusState private var isAddExampleFocused: Bool
    @State private var isAddingExample = false
    @State private var editingExampleIndex: Int?
    @State private var exampleTextFieldStr = ""
    @State private var showingTagSelection = false
    @State private var availableTags: [CDTag] = []
    @State private var showingDifficultyPicker = false
    @State private var selectedDifficulty: Difficulty = .new
    @StateObject private var dictionaryService = DictionaryService.shared
    @StateObject private var authenticationService = AuthenticationService.shared

    init(word: CDWord, dictionary: DictionaryService.SharedDictionary? = nil) {
        self._word = StateObject(wrappedValue: word)
        self.dictionary = dictionary
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 24) {
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
        .navigationTitle(word.wordItself ?? "")
        .background(Color(.systemGroupedBackground))
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showDeleteAlert()
                } label: {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
            }
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    word.isFavorite.toggle()
                    saveContext()
                    AnalyticsService.shared.logEvent(.wordFavoriteTapped)
                } label: {
                    Image(systemName: word.isFavorite
                          ? "heart.fill"
                          : "heart"
                    )
                    .animation(.easeInOut(duration: 0.2), value: word.isFavorite)
                }
            }
        }
        .sheet(isPresented: $showingTagSelection) {
            WordTagSelectionView(word: word, availableTags: availableTags)
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
        .onAppear {
            loadTags()
        }
    }

    private var transcriptionSectionView: some View {
        CustomSectionView(header: "Transcription") {
            TextField("Transcription", text: Binding(
                get: { word.phonetic ?? "" },
                set: { word.phonetic = $0 }
            ), axis: .vertical)
                .focused($isPhoneticsFocused)
                .clippedWithPaddingAndBackground()
        } headerTrailingContent: {
            if isPhoneticsFocused {
                SectionHeaderButton("Done") {
                    isPhoneticsFocused = false
                    saveContext()
                }
            } else {
                SectionHeaderButton("Listen", systemImage: "speaker.wave.2.fill") {
                    play(word.wordItself, isWord: true)
                }
            }
        }
    }

    private var partOfSpeechSectionView: some View {
        CustomSectionView(header: "Part Of Speech") {
            Text(word.partOfSpeech ?? "")
                .frame(maxWidth: .infinity, alignment: .leading)
                .clippedWithPaddingAndBackground()
                .contextMenu {
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

    private var definitionSectionView: some View {
        CustomSectionView(header: "Definition") {
            TextField("Definition", text: Binding(
                get: { word.definition ?? "" },
                set: { word.definition = $0 }
            ), axis: .vertical)
                .focused($isDefinitionFocused)
                .clippedWithPaddingAndBackground()
        } headerTrailingContent: {
            if isDefinitionFocused {
                SectionHeaderButton("Done") {
                    isDefinitionFocused = false
                    AnalyticsService.shared.logEvent(.wordDefinitionChanged)
                    saveContext()
                }
            } else {
                SectionHeaderButton("Listen", systemImage: "speaker.wave.2.fill") {
                    play(word.definition)
                    AnalyticsService.shared.logEvent(.wordDefinitionPlayed)
                }
            }
        }
    }

    private var difficultySectionView: some View {
        CustomSectionView(header: "Difficulty") {
            HStack {
                Text(getCurrentDifficulty().displayName)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Spacer()
                
                Button("Change") {
                    selectedDifficulty = getCurrentDifficulty()
                    showingDifficultyPicker = true
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            .clippedWithPaddingAndBackground()
        }
        .sheet(isPresented: $showingDifficultyPicker) {
            difficultyPickerView
        }
    }

    @ViewBuilder
    private var languageSectionView: some View {
        if word.shouldShowLanguageLabel {
            CustomSectionView(header: "Language") {
                HStack {
                    Text(word.languageDisplayName)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    if let languageCode = word.languageCode {
                        Text(languageCode.uppercased())
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.2))
                            .foregroundColor(.blue)
                            .clipShape(Capsule())
                    }
                }
                .clippedWithPaddingAndBackground()
            }
        }
    }
    
    private var difficultyPickerView: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Select Difficulty Level")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                VStack(spacing: 12) {
                    ForEach(Difficulty.allCases, id: \.self) { difficulty in
                        Button {
                            selectedDifficulty = difficulty
                        } label: {
                            HStack {
                                Text(difficulty.displayName)
                                    .font(.body)
                                    .foregroundColor(selectedDifficulty == difficulty ? .white : .primary)
                                
                                Spacer()
                                
                                if selectedDifficulty == difficulty {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.white)
                                }
                            }
                            .padding()
                            .background(selectedDifficulty == difficulty ? Color.blue : Color(.secondarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
                
                Spacer()
                
                HStack(spacing: 16) {
                    Button("Cancel") {
                        showingDifficultyPicker = false
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Save") {
                        updateDifficulty()
                        showingDifficultyPicker = false
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            }
            .padding()
            .navigationTitle("Difficulty")
            .navigationBarTitleDisplayMode(.inline)
        }
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
        CustomSectionView(header: "Tags") {
            if word.tagsArray.isEmpty {
                Text("No tags added yet.")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .clippedWithPaddingAndBackground()
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(word.tagsArray, id: \.id) { tag in
                        TagView(tag: tag)
                            .onTapGesture {
                                removeTag(tag)
                            }
                    }
                }
                .clippedWithBackground()
            }
        } headerTrailingContent: {
            SectionHeaderButton("Add Tag", systemImage: "plus") {
                availableTags = TagService.shared.getAllTags()
                showingTagSelection = true
            }
        }
    }

    private var examplesSectionView: some View {
        CustomSectionView(header: "Examples") {
            FormWithDivider {
                ForEach(Array(word.examplesDecoded.enumerated()), id: \.offset) { index, example in
                    Text(example)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .clippedWithPaddingAndBackground()
                        .contextMenu {
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
                        }
                }
                if isAddingExample {
                    HStack {
                        TextField("Type an example here", text: $exampleTextFieldStr, axis: .vertical)
                            .focused($isAddExampleFocused)

                        if isAddExampleFocused {
                            Button {
                                addExample(exampleTextFieldStr)
                                isAddingExample = false
                                exampleTextFieldStr = .empty
                                AnalyticsService.shared.logEvent(.wordExampleAdded)
                            } label: {
                                Image(systemName: "checkmark.rectangle.portrait.fill")
                            }
                        }
                    }
                    .padding(vertical: 12, horizontal: 16)
                } else {
                    Button("Add example", systemImage: "plus") {
                        withAnimation {
                            isAddingExample.toggle()
                            AnalyticsService.shared.logEvent(.wordAddExampleTapped)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(vertical: 12, horizontal: 16)
                }
            }
            .clippedWithBackground()
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

    private func loadTags() {
        availableTags = TagService.shared.getAllTags()
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
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(tag.colorValue.color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
