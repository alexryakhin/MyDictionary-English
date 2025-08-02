import SwiftUI
import Combine

struct WordDetailsContentView: View {

    @StateObject var word: CDWord
    @Environment(\.dismiss) private var dismiss

    @FocusState private var isPhoneticsFocused: Bool
    @FocusState private var isDefinitionFocused: Bool
    @FocusState private var isAddExampleFocused: Bool
    @State private var isAddingExample = false
    @State private var editingExampleIndex: Int?
    @State private var exampleTextFieldStr = ""
    @State private var isShowingAlert = false
    @State private var alertModel = AlertModel(title: .empty)
    @State private var showingTagSelection = false
    @State private var availableTags: [CDTag] = []

    init(word: CDWord) {
        self._word = StateObject(wrappedValue: word)
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 24) {
                transcriptionSectionView
                partOfSpeechSectionView
                definitionSectionView
                difficultySectionView
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
        .alert(isPresented: $isShowingAlert) {
            Alert(
                title: Text(alertModel.title),
                message: Text(alertModel.message ?? ""),
                primaryButton: .default(Text(alertModel.actionText ?? "OK")) {
                    alertModel.action?()
                },
                secondaryButton: .destructive(Text(alertModel.destructiveActionText ?? "Delete")) {
                    alertModel.destructiveAction?()
                }
            )
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
                    play(word.wordItself)
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
                    // TODO: Show difficulty picker
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            .clippedWithPaddingAndBackground()
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
                availableTags = ServiceManager.shared.tagService.getAllTags()
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
        do {
            try ServiceManager.shared.coreDataService.saveContext()
        } catch {
            // Handle error if needed
        }
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
        alertModel = AlertModel(
            title: "Delete word",
            message: "Are you sure you want to delete this word?",
            actionText: "Cancel",
            destructiveActionText: "Delete",
            action: {
                AnalyticsService.shared.logEvent(.wordRemovingCanceled)
            },
            destructiveAction: {
                deleteWord()
                dismiss()
            }
        )
        isShowingAlert = true
    }

    private func deleteWord() {
        ServiceManager.shared.coreDataService.context.delete(word)
        saveContext()
        AnalyticsService.shared.logEvent(.wordRemoved)
    }

    private func loadTags() {
        availableTags = ServiceManager.shared.tagService.getAllTags()
    }

    private func removeTag(_ tag: CDTag) {
        try? ServiceManager.shared.tagService.removeTagFromWord(tag, word: word)
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
