import SwiftUI
import Combine
import Flow

struct WordDetailsContentView: View {

    @StateObject var word: CDWord
    @Environment(\.dismiss) private var dismiss

    @FocusState private var isPhoneticsFocused: Bool
    @FocusState private var isDefinitionFocused: Bool
    @State private var showingTagSelection = false

    init(word: CDWord) {
        self._word = StateObject(wrappedValue: word)
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                transcriptionSectionView
                partOfSpeechSectionView
                meaningsSectionView
                difficultySectionView
                languageSectionView
                tagsSectionView
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

    private var meaningsSectionView: some View {
        let meanings = word.meaningsArray
        let showLimited = meanings.count > 3
        let displayMeanings = showLimited ? Array(meanings.prefix(3)) : meanings
        
        return CustomSectionView(header: meanings.count > 1 ? "Meanings (\(meanings.count))" : "Meaning", headerFontStyle: .stealth) {
            if meanings.isEmpty {
                // Fallback to legacy definition if no meanings exist
                TextField(Loc.Words.WordDetails.definition, text: Binding(
                    get: { word.definition ?? "" },
                    set: { word.definition = $0 }
                ), axis: .vertical)
                .focused($isDefinitionFocused)
                .fontWeight(.semibold)
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
                        NavigationManager.shared.navigate(to: .wordMeaningsList(word))
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
            } else {
                HeaderButton(icon: "plus", size: .small) {
                    addNewMeaning()
                }
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
    
    @ViewBuilder
    private func meaningRowView(meaning: CDMeaning, index: Int) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("\(index).")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(meaning.definition ?? "")
                    .fontWeight(.semibold)
                
                Spacer()
                
                AsyncHeaderButton(
                    icon: "speaker.wave.2.fill",
                    size: .small
                ) {
                    try await play(meaning.definition)
                }
                .disabled(TTSPlayer.shared.isPlaying)
            }
            
            // Show examples for this meaning
            let examples = meaning.examplesDecoded
            if !examples.isEmpty {
                ForEach(Array(examples.enumerated()), id: \.offset) { exampleIndex, example in
                    HStack {
                        Text("•")
                            .foregroundColor(.secondary)
                        Text(example)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .padding(.leading, 16)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private func showAllMeanings() {
        // TODO: Navigate to full meanings list view
        // This could be a sheet or navigation to a dedicated view
    }
    
    private func addNewMeaning() {
        do {
            let _ = try word.addMeaning(definition: "New definition", examples: [])
            saveContext()
        } catch {
            errorReceived(error)
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
            errorReceived(title: Loc.Words.WordDetails.deleteFailed, error)
        }
    }

    private func removeTag(_ tag: CDTag) {
        try? TagService.shared.removeTagFromWord(tag, word: word)
        saveContext()
        AnalyticsService.shared.logEvent(.tagRemovedFromWord)
    }
}
