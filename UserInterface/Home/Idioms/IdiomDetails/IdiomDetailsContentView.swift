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
    @State private var isShowingAlert = false
    @State private var alertModel = AlertModel(title: .empty)

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
                    idiom.isFavorite.toggle()
                    saveContext()
                    AnalyticsService.shared.logEvent(.idiomFavoriteTapped)
                } label: {
                    Image(systemName: idiom.isFavorite
                          ? "heart.fill"
                          : "heart"
                    )
                    .animation(.easeInOut(duration: 0.2), value: idiom.isFavorite)
                }
            }
        }
        // Removed dismissPublisher - we'll handle dismissal in the delete action
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
        } headerTrailingContent: {
            if isIdiomInputFocused {
                SectionHeaderButton("Done") {
                    isIdiomInputFocused = false
                    saveContext()
                    AnalyticsService.shared.logEvent(.idiomChanged)
                }
            } else {
                SectionHeaderButton("Listen", systemImage: "speaker.wave.2.fill") {
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
        } headerTrailingContent: {
            if isDefinitionFocused {
                SectionHeaderButton("Done") {
                    isDefinitionFocused = false
                    saveContext()
                    AnalyticsService.shared.logEvent(.idiomDefinitionChanged)
                }
            } else {
                SectionHeaderButton("Listen", systemImage: "speaker.wave.2.fill") {
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
        alertModel = AlertModel(
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
        isShowingAlert = true
    }

    private func deleteIdiom() {
        ServiceManager.shared.coreDataService.context.delete(idiom)
        saveContext()
        AnalyticsService.shared.logEvent(.idiomRemoved)
    }

    // Removed dismissPublisher - no longer needed
}
