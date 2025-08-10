import SwiftUI

struct WordDetailsView: View {

    @StateObject var word: CDWord
    @Environment(\.dismiss) private var dismiss

    @FocusState private var isPhoneticsFocused: Bool
    @FocusState private var isDefinitionFocused: Bool
    @FocusState private var isAddExampleFocused: Bool
    @State private var isAddingExample = false
    @State private var editingExampleIndex: Int?
    @State private var exampleTextFieldStr = ""
    @State private var showingDifficultyPicker = false
    @State private var selectedDifficulty: Difficulty = .new

    init(word: CDWord) {
        self._word = StateObject(wrappedValue: word)
    }

    var body: some View {
        VStack(spacing: 0) {
            Text(word.wordItself ?? "")
                .font(.largeTitle)
                .bold()
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(vertical: 12, horizontal: 16)
                .padding(.top, 8)
                .contextMenu {
                    Button("Copy") {
                        let pasteboard = NSPasteboard.general
                        pasteboard.declareTypes([NSPasteboard.PasteboardType.string], owner: nil)
                        pasteboard.setString(word.wordItself ?? "", forType: .string)
                    }
                }
            Divider()
            
            ScrollView {
                LazyVStack(spacing: 24) {
                    transcriptionSectionView
                    partOfSpeechSectionView
                    definitionSectionView
                    difficultySectionView
                    languageSectionView
                    examplesSectionView
                }
                .padding(vertical: 12, horizontal: 16)
            }
        }
        .toolbar {
            Button(role: .destructive) {
                deleteWord()
                AnalyticsService.shared.logEvent(.removeWordMenuButtonTapped)
            } label: {
                Image(systemName: "trash")
                    .foregroundStyle(.red)
            }

            Button {
                word.isFavorite.toggle()
                saveContext()
                AnalyticsService.shared.logEvent(.wordFavoriteTapped)
            } label: {
                Image(systemName: "\(word.isFavorite ? "heart.fill" : "heart")")
                    .foregroundStyle(.accent)
                    .animation(.easeInOut(duration: 0.2), value: word.isFavorite)
            }
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
        .sheet(isPresented: $showingDifficultyPicker) {
            difficultyPickerView
        }
    }

    private var transcriptionSectionView: some View {
        CustomSectionView(header: "Transcription") {
            let text = Binding {
                word.phonetic ?? ""
            } set: {
                word.phonetic = $0
                saveContext()
                AnalyticsService.shared.logEvent(.wordPhoneticsChanged)
            }
            TextField("Transcription", text: text, axis: .vertical)
                .textFieldStyle(.plain)
                .focused($isPhoneticsFocused)
                .clippedWithPaddingAndBackground()
        } headerTrailingContent: {
            if isPhoneticsFocused {
                SectionHeaderButton("Done") {
                    isPhoneticsFocused = false
                    saveContext()
                    AnalyticsService.shared.logEvent(.wordPhoneticsChanged)
                }
            } else {
                SectionHeaderButton("Listen", systemImage: "speaker.wave.2.fill") {
                    play(word.wordItself)
                    AnalyticsService.shared.logEvent(.wordPlayed)
                }
            }
        }
    }

    private var partOfSpeechSectionView: some View {
        CustomSectionView(header: "Part Of Speech") {
            Menu {
                ForEach(PartOfSpeech.allCases, id: \.self) { partCase in
                    Button {
                        word.partOfSpeech = partCase.rawValue
                        saveContext()
                        AnalyticsService.shared.logEvent(.partOfSpeechChanged)
                    } label: {
                        Text(partCase.rawValue)
                        if word.partOfSpeech == partCase.rawValue {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            } label: {
                Text(word.partOfSpeech ?? "")
            }
            .buttonStyle(.borderless)
            .frame(maxWidth: .infinity, alignment: .leading)
            .clippedWithPaddingAndBackground()
        }
    }

    private var definitionSectionView: some View {
        CustomSectionView(header: "Definition") {
            let text = Binding {
                word.definition ?? ""
            } set: {
                word.definition = $0
                saveContext()
                AnalyticsService.shared.logEvent(.wordDefinitionChanged)
            }
            TextField("Definition", text: text, axis: .vertical)
                .textFieldStyle(.plain)
                .focused($isDefinitionFocused)
                .clippedWithPaddingAndBackground()
        } headerTrailingContent: {
            if isDefinitionFocused {
                SectionHeaderButton("Done") {
                    isDefinitionFocused = false
                    saveContext()
                    AnalyticsService.shared.logEvent(.wordDefinitionChanged)
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
                .foregroundStyle(.blue)
            }
            .clippedWithPaddingAndBackground()
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
                                .foregroundStyle(selectedDifficulty == difficulty ? .white : .primary)
                            
                            Spacer()
                            
                            if selectedDifficulty == difficulty {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.white)
                            }
                        }
                        .padding()
                        .background(selectedDifficulty == difficulty ? Color.blue : Color(.secondarySystemFill))
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
        .frame(width: 400, height: 300)
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
    
    private func updateDifficulty() {
        word.difficultyLevel = selectedDifficulty.level
        
        do {
            try CoreDataService.shared.saveContext()
            AnalyticsService.shared.logEvent(.wordDifficultyChanged)
        } catch {
            print("❌ Failed to update word difficulty: \(error)")
        }
    }

    private var examplesSectionView: some View {
        CustomSectionView(header: "Examples") {
            let examples = word.examplesDecoded ?? []
            FormWithDivider {
                ForEach(Array(examples.enumerated()), id: \.offset) { index, example in
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
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                }
                if isAddingExample {
                    HStack {
                        TextField("Type an example here", text: $exampleTextFieldStr, axis: .vertical)
                            .textFieldStyle(.plain)
                            .focused($isAddExampleFocused)

                        if isAddExampleFocused {
                            Button {
                                addExample(exampleTextFieldStr)
                                isAddingExample = false
                                exampleTextFieldStr = .empty
                                AnalyticsService.shared.logEvent(.wordExampleAdded)
                            } label: {
                                Image(systemName: "checkmark.rectangle.portrait.fill")
                                    .font(.title3)
                                    .foregroundStyle(.accent)
                            }
                            .buttonStyle(.borderless)
                        }
                    }
                    .padding(vertical: 12, horizontal: 16)
                } else {
                    Button {
                        withAnimation {
                            isAddingExample.toggle()
                            AnalyticsService.shared.logEvent(.wordAddExampleTapped)
                        }
                    } label: {
                        Label("Add example", systemImage: "plus")
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.borderless)
                    .padding(vertical: 12, horizontal: 16)
                }
            }
            .clippedWithBackground()
        }
    }

    private func deleteWord() {
        guard let id = word.id?.uuidString else { return }
        WordsProvider.shared.deleteWord(with: id)
    }

    private func saveContext() {
        Task {
            // Mark word as unsynced when it's modified and update updatedAt
            word.isSynced = false
            word.updatedAt = Date()
            
            do {
                try CoreDataService.shared.saveContext()
                
                // Immediately sync to Firestore for real-time updates
                if let userId = AuthenticationService.shared.userId {
                    try await DataSyncService.shared.syncWordToFirestore(word: word, userId: userId)
                    print("✅ [WordDetails] Word synced to Firestore immediately")
                }
            } catch {
                print("❌ Failed to save context: \(error)")
            }
        }
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

    private func play(_ text: String?) {
        Task { @MainActor in
            guard let text else { return }

            do {
                try await ServiceManager.shared.ttsPlayer.play(text)
            } catch {
                // Handle error if needed
            }
        }
    }
}
