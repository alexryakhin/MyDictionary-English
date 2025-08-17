import SwiftUI
import Combine

struct IdiomDetailsContentView: View {

    @StateObject var idiom: CDIdiom
    @Environment(\.dismiss) private var dismiss

    @FocusState private var isIdiomInputFocused: Bool
    @FocusState private var isDefinitionFocused: Bool
    @FocusState private var isAddExampleFocused: Bool
    @State private var isAddingExample = false
    @State private var editingExampleIndex: Int?
    @State private var exampleTextFieldStr = ""

    init(idiom: CDIdiom) {
        self._idiom = StateObject(wrappedValue: idiom)
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                idiomSectionView
                definitionSectionView
                examplesSectionView
            }
            .padding(.horizontal, 16)
            .animation(.default, value: idiom)
        }
        .groupedBackground()
        .navigation(
            title: Loc.idiomDetails.localized,
            mode: .inline,
            showsBackButton: true,
            trailingContent: {
                HeaderButton(icon: "trash", color: .red) {
                    showDeleteAlert()
                }
                HeaderButton(icon: idiom.isFavorite ? "heart.fill" : "heart") {
                    idiom.isFavorite.toggle()
                    saveContext()
                    AnalyticsService.shared.logEvent(.idiomFavoriteTapped)
                }
                .animation(.easeInOut(duration: 0.2), value: idiom.isFavorite)
            }
        )
        .alert(Loc.editExample.localized, isPresented: .constant(editingExampleIndex != nil), presenting: editingExampleIndex) { index in
            TextField(Loc.examples.localized, text: $exampleTextFieldStr)
            Button(Loc.cancel.localized, role: .cancel) {
                AnalyticsService.shared.logEvent(.idiomExampleChangingCanceled)
            }
            Button(Loc.save.localized) {
                updateExample(at: index, text: exampleTextFieldStr)
                editingExampleIndex = nil
                exampleTextFieldStr = .empty
                AnalyticsService.shared.logEvent(.idiomExampleUpdated)
            }
        }
    }

    private var idiomSectionView: some View {
        CustomSectionView(header: Loc.idiom.localized, headerFontStyle: .stealth) {
            TextField(Loc.idiom.localized, text: Binding(
                get: { idiom.idiomItself ?? "" },
                set: { idiom.idiomItself = $0 }
            ), axis: .vertical)
                .font(.system(.headline, design: .rounded))
                .focused($isIdiomInputFocused)
        } trailingContent: {
            if isIdiomInputFocused {
                HeaderButton(Loc.done.localized, size: .small) {
                    isIdiomInputFocused = false
                    saveContext()
                    AnalyticsService.shared.logEvent(.idiomChanged)
                }
            } else {
                HeaderButton(Loc.listen.localized, icon: "speaker.wave.2.fill", size: .small) {
                    play(idiom.idiomItself)
                }
            }
        }
    }

    private var definitionSectionView: some View {
        CustomSectionView(header: Loc.definition.localized, headerFontStyle: .stealth) {
            TextField(Loc.definition.localized, text: Binding(
                get: { idiom.definition ?? "" },
                set: { idiom.definition = $0 }
            ), axis: .vertical)
                .focused($isDefinitionFocused)
        } trailingContent: {
            if isDefinitionFocused {
                HeaderButton(Loc.done.localized, size: .small) {
                    isDefinitionFocused = false
                    saveContext()
                    AnalyticsService.shared.logEvent(.idiomDefinitionChanged)
                }
            } else {
                HeaderButton(Loc.listen.localized, icon: "speaker.wave.2.fill", size: .small) {
                    play(idiom.definition)
                    AnalyticsService.shared.logEvent(.idiomDefinitionPlayed)
                }
            }
        }
    }

    private var examplesSectionView: some View {
        CustomSectionView(
            header: Loc.examples.localized,
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
                                    Label(Loc.listen.localized, systemImage: "speaker.wave.2.fill")
                                }
                                Button {
                                    exampleTextFieldStr = example
                                    editingExampleIndex = index
                                    AnalyticsService.shared.logEvent(.idiomExampleChangeButtonTapped)
                                } label: {
                                    Label(Loc.edit.localized, systemImage: "pencil")
                                }
                                Section {
                                    Button(role: .destructive) {
                                        removeExample(at: index)
                                        AnalyticsService.shared.logEvent(.idiomExampleRemoved)
                                    } label: {
                                        Label(Loc.delete.localized, systemImage: "trash")
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
                Text(Loc.noExamplesYet.localized)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
            }

            if isAddingExample {
                InputView(
                    Loc.typeExampleHere.localized,
                    submitLabel: .done,
                    text: $exampleTextFieldStr,
                    onSubmit: {
                        addExample(exampleTextFieldStr)
                        isAddingExample = false
                        exampleTextFieldStr = .empty
                        AnalyticsService.shared.logEvent(.idiomExampleAdded)
                    },
                    trailingButtonLabel: Loc.cancel.localized
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
                HeaderButton(Loc.save.localized, icon: "checkmark", size: .small) {
                    addExample(exampleTextFieldStr)
                    isAddingExample = false
                    exampleTextFieldStr = .empty
                    AnalyticsService.shared.logEvent(.idiomExampleAdded)
                }
            } else {
                HeaderButton(Loc.addExample.localized, icon: "plus", size: .small) {
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
        let alertModel = AlertModel(
            title: Loc.deleteIdiom.localized,
            message: Loc.deleteIdiomConfirmation.localized,
            actionText: Loc.cancel.localized,
            destructiveActionText: Loc.delete.localized,
            action: {
                AnalyticsService.shared.logEvent(.idiomRemovingCanceled)
            },
            destructiveAction: {
                deleteIdiom()
                dismiss()
            }
        )
        AlertCenter.shared.showAlert(with: alertModel)
    }

    private func deleteIdiom() {
        CoreDataService.shared.context.delete(idiom)
        saveContext()
        AnalyticsService.shared.logEvent(.idiomRemoved)
    }
}
