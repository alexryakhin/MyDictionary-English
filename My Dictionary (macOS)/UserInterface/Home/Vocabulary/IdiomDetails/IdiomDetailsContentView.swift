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
        .navigationTitle(Loc.Navigation.idiomDetails.localized)
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
                .help(Loc.Words.favorite.localized)

                // Delete button
                Button {
                    showDeleteAlert()
                } label: {
                    Image(systemName: "trash")
                        .foregroundStyle(.red)
                }
                .help(Loc.Idioms.deleteIdiom.localized)
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
        CustomSectionView(header: Loc.Idioms.idiom.localized, headerFontStyle: .stealth) {
            TextField(
                Loc.Idioms.idiom.localized,
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
                HeaderButton(Loc.Actions.done.localized, size: .small) {
                    isIdiomInputFocused = false
                    saveContext()
                    AnalyticsService.shared.logEvent(.idiomChanged)
                }
            } else {
                HeaderButton(Loc.Actions.listen.localized, icon: "speaker.wave.2.fill", size: .small) {
                    play(idiom.idiomItself)
                }
            }
        }
    }

    private var definitionSectionView: some View {
        CustomSectionView(header: Loc.Words.definition.localized, headerFontStyle: .stealth) {
            TextField(
                Loc.Words.definition.localized,
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
                HeaderButton(Loc.Actions.done.localized, size: .small) {
                    isDefinitionFocused = false
                    saveContext()
                    AnalyticsService.shared.logEvent(.idiomDefinitionChanged)
                }
            } else {
                HeaderButton(Loc.Actions.listen.localized, icon: "speaker.wave.2.fill", size: .small) {
                    play(idiom.definition)
                    AnalyticsService.shared.logEvent(.idiomDefinitionPlayed)
                }
            }
        }
    }

    private var difficultySectionView: some View {
        CustomSectionView(
            header: Loc.Words.difficulty.localized,
            headerFontStyle: .stealth
        ) {
            let difficulty = idiom.difficultyLevel
            VStack(alignment: .leading, spacing: 4) {
                Label(difficulty.displayName, systemImage: difficulty.imageName)
                    .foregroundStyle(difficulty.color)
                    .fontWeight(.semibold)

                Text("\(Loc.Words.score.localized): \(idiom.difficultyScore)")
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
        if idiom.shouldShowLanguageLabel {
            CustomSectionView(
                header: Loc.Words.language.localized,
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
            header: Loc.Words.tags.localized,
            headerFontStyle: .stealth
        ) {
            if idiom.tagsArray.isEmpty {
                Text(Loc.Words.noTagsAddedYet.localized)
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
            HeaderButton(Loc.Tags.addTag.localized, icon: "plus", size: .small) {
                showingTagSelection = true
            }
        }
    }

    private var examplesSectionView: some View {
        CustomSectionView(
            header: Loc.Idioms.examples.localized,
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
                                    play(example)
                                    AnalyticsService.shared.logEvent(.idiomExamplePlayed)
                                } label: {
                                    Label(Loc.Actions.listen.localized, systemImage: "speaker.wave.2.fill")
                                }
                                Button {
                                    exampleTextFieldStr = example
                                    editingExampleIndex = index
                                    AnalyticsService.shared.logEvent(.idiomExampleChangeButtonTapped)
                                } label: {
                                    Label(Loc.Actions.edit.localized, systemImage: "pencil")
                                }
                                Section {
                                    Button(role: .destructive) {
                                        removeExample(at: index)
                                        AnalyticsService.shared.logEvent(.idiomExampleRemoved)
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
                Text(Loc.Idioms.noExamplesYet.localized)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
            }

            if isAddingExample {
                InputView(
                    Loc.Idioms.typeExampleHere.localized,
                    submitLabel: .done,
                    text: $exampleTextFieldStr,
                    onSubmit: {
                        addExample(exampleTextFieldStr)
                        isAddingExample = false
                        exampleTextFieldStr = .empty
                        AnalyticsService.shared.logEvent(.idiomExampleAdded)
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
                    AnalyticsService.shared.logEvent(.idiomExampleAdded)
                }
            } else {
                HeaderButton(Loc.Idioms.addExample.localized, icon: "plus", size: .small) {
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

    private func play(_ text: String?) {
        Task { @MainActor in
            guard let text else { return }

            do {
                try await TTSPlayer.shared.play(
                    text,
                    targetLanguage: Locale.current.language.languageCode?.identifier
                )
            } catch {
                errorReceived(error)
            }
        }
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
                title: Loc.Idioms.deleteIdiom.localized,
                message: Loc.Idioms.deleteIdiomConfirmation.localized,
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
