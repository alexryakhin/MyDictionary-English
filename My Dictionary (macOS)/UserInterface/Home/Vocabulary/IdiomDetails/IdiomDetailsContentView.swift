import SwiftUI
import Combine
import Flow

struct IdiomDetailsView: View {

    @StateObject var idiom: CDIdiom
    @Environment(\.dismiss) private var dismiss

    @FocusState private var isIdiomInputFocused: Bool
    @FocusState private var isDefinitionFocused: Bool
    @FocusState private var isAddExampleFocused: Bool

    @State private var isAddingExample = false
    @State private var editingExampleIndex: Int?
    @State private var exampleTextFieldStr = ""
    @State private var showingTagSelection = false

    init(idiom: CDIdiom) {
        self._idiom = StateObject(wrappedValue: idiom)
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                idiomSectionView
                definitionSectionView
                difficultySectionView
                languageSectionView
                tagsSectionView
                examplesSectionView
            }
            .padding(12)
            .animation(.default, value: idiom)
        }
        .groupedBackground()
        .navigationTitle(Loc.Navigation.idiomDetails)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                // Favorite button
                Button {
                    idiom.isFavorite.toggle()
                    saveContext()
                    AnalyticsService.shared.logEvent(.idiomFavoriteTapped)
                } label: {
                    Image(systemName: idiom.isFavorite ? "heart.fill" : "heart")
                        .foregroundStyle(idiom.isFavorite ? .red : .primary)
                }
                .help(Loc.Words.favorite)

                // Delete button
                Button {
                    showDeleteAlert()
                } label: {
                    Image(systemName: "trash")
                        .foregroundStyle(.red)
                }
                .help(Loc.Words.deleteIdiom)
            }
        }
        .sheet(item: $editingExampleIndex) { index in
            EditExampleAlert(
                exampleText: $exampleTextFieldStr,
                onCancel: {
                    AnalyticsService.shared.logEvent(.idiomExampleChangingCanceled)
                    editingExampleIndex = nil
                },
                onSave: {
                    updateExample(at: index, text: exampleTextFieldStr)
                    editingExampleIndex = nil
                    exampleTextFieldStr = .empty
                    AnalyticsService.shared.logEvent(.idiomExampleUpdated)
                }
            )
        }
        .sheet(isPresented: $showingTagSelection) {
            IdiomTagSelectionView(idiom: idiom)
        }
    }

    private var idiomSectionView: some View {
        CustomSectionView(header: Loc.Words.idiom, headerFontStyle: .stealth) {
            TextField(
                Loc.Words.idiom,
                text: Binding(
                    get: { idiom.idiomItself ?? "" },
                    set: { idiom.idiomItself = $0 }
                ),
                axis: .vertical
            )
            .textFieldStyle(.plain)
            .font(.system(.headline, design: .rounded))
            .focused($isIdiomInputFocused)
        } trailingContent: {
            if isIdiomInputFocused {
                HeaderButton(Loc.Actions.done, size: .small) {
                    isIdiomInputFocused = false
                    saveContext()
                    AnalyticsService.shared.logEvent(.idiomChanged)
                }
            } else {
                AsyncHeaderButton(
                    Loc.Actions.listen,
                    icon: "speaker.wave.2.fill",
                    size: .small
                ) {
                    try await play(idiom.idiomItself)
                }
                .disabled(TTSPlayer.shared.isPlaying)
            }
        }
    }

    private var definitionSectionView: some View {
        CustomSectionView(header: Loc.Words.definition, headerFontStyle: .stealth) {
            TextField(
                Loc.Words.definition,
                text: Binding(
                    get: { idiom.definition ?? "" },
                    set: { idiom.definition = $0 }
                ),
                axis: .vertical
            )
            .textFieldStyle(.plain)
            .focused($isDefinitionFocused)
        } trailingContent: {
            if isDefinitionFocused {
                HeaderButton(Loc.Actions.done, size: .small) {
                    isDefinitionFocused = false
                    saveContext()
                    AnalyticsService.shared.logEvent(.idiomDefinitionChanged)
                }
            } else {
                AsyncHeaderButton(
                    Loc.Actions.listen,
                    icon: "speaker.wave.2.fill",
                    size: .small
                ) {
                    try await play(idiom.definition)
                    AnalyticsService.shared.logEvent(.idiomDefinitionPlayed)
                }
                .disabled(TTSPlayer.shared.isPlaying)
            }
        }
    }

    private var difficultySectionView: some View {
        CustomSectionView(
            header: Loc.Words.difficulty,
            headerFontStyle: .stealth
        ) {
            let difficulty = idiom.difficultyLevel
            VStack(alignment: .leading, spacing: 4) {
                Label(difficulty.displayName, systemImage: difficulty.imageName)
                    .foregroundStyle(difficulty.color)
                    .fontWeight(.semibold)

                Text("\(Loc.Words.score): \(idiom.difficultyScore)")
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
        if idiom.shouldShowLanguageLabel {
            CustomSectionView(
                header: Loc.Words.language,
                headerFontStyle: .stealth
            ) {
                HStack {
                    Text(idiom.languageDisplayName)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    if let languageCode = idiom.languageCode {
                        TagView(text: languageCode.uppercased(), color: .blue, size: .mini)
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
            if idiom.tagsArray.isEmpty {
                Text(Loc.Words.noTagsAddedYet)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                HFlow(alignment: .top, spacing: 8) {
                    ForEach(idiom.tagsArray) { tag in
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

    private var examplesSectionView: some View {
        CustomSectionView(
            header: Loc.Words.examples,
            headerFontStyle: .stealth,
            hPadding: 0
        ) {
            if idiom.examplesDecoded.isNotEmpty {
                FormWithDivider {
                    ForEach(Array(idiom.examplesDecoded.enumerated()), id: \.offset) { index, example in
                        HStack {
                            Text(example)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            Menu {
                                Button {
                                    Task {
                                        try await play(example)
                                    }
                                    AnalyticsService.shared.logEvent(.idiomExamplePlayed)
                                } label: {
                                    Label(Loc.Actions.listen, systemImage: "speaker.wave.2.fill")
                                }
                                .disabled(TTSPlayer.shared.isPlaying)
                                Button {
                                    exampleTextFieldStr = example
                                    editingExampleIndex = index
                                    AnalyticsService.shared.logEvent(.idiomExampleChangeButtonTapped)
                                } label: {
                                    Label(Loc.Actions.edit, systemImage: "pencil")
                                }
                                Section {
                                    Button(role: .destructive) {
                                        removeExample(at: index)
                                        AnalyticsService.shared.logEvent(.idiomExampleRemoved)
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
                            .buttonStyle(.plain)
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
                    Loc.Words.typeExampleHere,
                    submitLabel: .done,
                    text: $exampleTextFieldStr,
                    onSubmit: {
                        addExample(exampleTextFieldStr)
                        isAddingExample = false
                        exampleTextFieldStr = .empty
                        AnalyticsService.shared.logEvent(.idiomExampleAdded)
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
                    AnalyticsService.shared.logEvent(.idiomExampleAdded)
                }
            } else {
                HeaderButton(Loc.Words.addExample, icon: "plus", size: .small) {
                    withAnimation {
                        isAddingExample.toggle()
                        AnalyticsService.shared.logEvent(.idiomAddExampleTapped)
                    }
                }
            }
        }
    }

    // MARK: - Private Methods

    private func saveContext() {
        do {
            try CoreDataService.shared.saveContext()
        } catch {
            errorReceived(error)
        }
    }

    private func play(_ text: String?) async throws {
        guard let text else { return }
        try await TTSPlayer.shared.play(
            text,
            targetLanguage: Locale.current.language.languageCode?.identifier
        )
    }

    private func addExample(_ example: String) {
        guard !example.isEmpty else { return }
        var currentExamples = idiom.examplesDecoded
        currentExamples.append(example)
        try? idiom.updateExamples(currentExamples)
        saveContext()
    }

    private func updateExample(at index: Int, text: String) {
        guard !text.isEmpty else { return }
        var currentExamples = idiom.examplesDecoded
        currentExamples[index] = text
        try? idiom.updateExamples(currentExamples)
        saveContext()
    }

    private func removeExample(at index: Int) {
        var currentExamples = idiom.examplesDecoded
        currentExamples.remove(at: index)
        try? idiom.updateExamples(currentExamples)
        saveContext()
    }

    private func showDeleteAlert() {
        AlertCenter.shared.showAlert(
            with: .deleteConfirmation(
                title: Loc.Words.deleteIdiom,
                message: Loc.Words.deleteIdiomConfirmation,
                onCancel: {
                    AnalyticsService.shared.logEvent(.idiomRemovingCanceled)
                },
                onDelete: {
                    deleteIdiom()
                    dismiss()
                }
            )
        )
    }

    private func deleteIdiom() {
        CoreDataService.shared.context.delete(idiom)
        saveContext()
        AnalyticsService.shared.logEvent(.idiomRemoved)
    }
}
