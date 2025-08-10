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
            LazyVStack(spacing: 24) {
                idiomSectionView
                definitionSectionView
                examplesSectionView
            }
            .padding(vertical: 12, horizontal: 16)
            .animation(.default, value: idiom)
        }
        .groupedBackground()
        .navigation(
            title: "Idiom Details",
            mode: .inline,
            showsBackButton: true,
            trailingContent: {
                HeaderButton(icon: "trash") {
                    showDeleteAlert()
                }
                .tint(.red)
                HeaderButton(icon: idiom.isFavorite ? "heart.fill" : "heart") {
                    idiom.isFavorite.toggle()
                    saveContext()
                    AnalyticsService.shared.logEvent(.idiomFavoriteTapped)
                }
                .animation(.easeInOut(duration: 0.2), value: idiom.isFavorite)
            }
        )
        .alert("Edit example", isPresented: .constant(editingExampleIndex != nil), presenting: editingExampleIndex) { index in
            TextField("Example", text: $exampleTextFieldStr)
            Button("Cancel", role: .cancel) {
                AnalyticsService.shared.logEvent(.idiomExampleChangingCanceled)
            }
            Button("Save") {
                updateExample(at: index, text: exampleTextFieldStr)
                editingExampleIndex = nil
                exampleTextFieldStr = .empty
                AnalyticsService.shared.logEvent(.idiomExampleUpdated)
            }
        }
    }

    private var idiomSectionView: some View {
        CustomSectionView(header: "Idiom") {
            TextField("Idiom", text: Binding(
                get: { idiom.idiomItself ?? "" },
                set: { idiom.idiomItself = $0 }
            ), axis: .vertical)
                .font(.system(.headline, design: .rounded))
                .focused($isIdiomInputFocused)
                .clippedWithPaddingAndBackground()
        } trailingContent: {
            if isIdiomInputFocused {
                HeaderButton(text: "Done") {
                    isIdiomInputFocused = false
                    saveContext()
                    AnalyticsService.shared.logEvent(.idiomChanged)
                }
            } else {
                HeaderButton(text: "Listen", icon: "speaker.wave.2.fill") {
                    play(idiom.idiomItself)
                }
            }
        }
    }

    private var definitionSectionView: some View {
        CustomSectionView(header: "Definition") {
            TextField("Definition", text: Binding(
                get: { idiom.definition ?? "" },
                set: { idiom.definition = $0 }
            ), axis: .vertical)
                .focused($isDefinitionFocused)
                .clippedWithPaddingAndBackground()
        } trailingContent: {
            if isDefinitionFocused {
                HeaderButton(text: "Done") {
                    isDefinitionFocused = false
                    saveContext()
                    AnalyticsService.shared.logEvent(.idiomDefinitionChanged)
                }
            } else {
                HeaderButton(text: "Listen", icon: "speaker.wave.2.fill") {
                    play(idiom.definition)
                    AnalyticsService.shared.logEvent(.idiomDefinitionPlayed)
                }
            }
        }
    }

    private var examplesSectionView: some View {
        CustomSectionView(header: "Examples") {
            FormWithDivider {
                ForEach(Array(idiom.examplesDecoded.enumerated()), id: \.offset) { index, example in
                    Text(example)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .clippedWithPaddingAndBackground()
                        .contextMenu {
                            Button {
                                play(example)
                                AnalyticsService.shared.logEvent(.idiomExamplePlayed)
                            } label: {
                                Label("Listen", systemImage: "speaker.wave.2.fill")
                            }
                            Button {
                                exampleTextFieldStr = example
                                editingExampleIndex = index
                                AnalyticsService.shared.logEvent(.idiomExampleChangeButtonTapped)
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            Section {
                                Button(role: .destructive) {
                                    removeExample(at: index)
                                    AnalyticsService.shared.logEvent(.idiomExampleRemoved)
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
                                AnalyticsService.shared.logEvent(.idiomExampleAdded)
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
                            AnalyticsService.shared.logEvent(.idiomAddExampleTapped)
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
            try CoreDataService.shared.saveContext()
        } catch {
            // Handle error if needed
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
                // Handle error if needed
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
            title: "Delete idiom",
            message: "Are you sure you want to delete this idiom?",
            actionText: "Cancel",
            destructiveActionText: "Delete",
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

    // Removed dismissPublisher - no longer needed
}
