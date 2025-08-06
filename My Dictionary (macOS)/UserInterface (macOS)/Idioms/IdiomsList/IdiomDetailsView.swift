import SwiftUI

struct IdiomDetailsView: View {

    @StateObject var idiom: CDIdiom
    @Environment(\.dismiss) private var dismiss

    @FocusState private var isIdiomInputFocused: Bool
    @FocusState private var isDefinitionFieldFocused: Bool
    @FocusState private var isAddExampleFocused: Bool
    @State private var isAddingExample = false
    @State private var editingExampleIndex: Int?
    @State private var exampleTextFieldStr = ""

    init(idiom: CDIdiom) {
        self._idiom = StateObject(wrappedValue: idiom)
    }

    var body: some View {
        VStack(spacing: 0) {
            Text(idiom.idiomItself ?? "")
                .font(.largeTitle)
                .bold()
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(vertical: 12, horizontal: 16)
                .padding(.top, 8)
                .contextMenu {
                    Button("Copy") {
                        let pasteboard = NSPasteboard.general
                        pasteboard.declareTypes([NSPasteboard.PasteboardType.string], owner: nil)
                        pasteboard.setString(idiom.idiomItself ?? "", forType: .string)
                    }
                }
            Divider()
            
            ScrollView {
                LazyVStack(spacing: 16) {
                    idiomSectionView
                    definitionSectionView
                    examplesSectionView
                }
                .padding(vertical: 12, horizontal: 16)
            }
        }
        .toolbar {
            Button(role: .destructive) {
                deleteIdiom()
                AnalyticsService.shared.logEvent(.removeIdiomMenuButtonTapped)
            } label: {
                Image(systemName: "trash")
                    .foregroundStyle(.red)
            }

            Button {
                idiom.isFavorite.toggle()
                saveContext()
                AnalyticsService.shared.logEvent(.idiomFavoriteTapped)
            } label: {
                Image(systemName: "\(idiom.isFavorite ? "heart.fill" : "heart")")
                    .foregroundStyle(.accent)
                    .animation(.easeInOut(duration: 0.2), value: idiom.isFavorite)
            }
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
            }
        }
    }

    // MARK: - Primary Content

    private var idiomSectionView: some View {
        CustomSectionView(header: "Idiom") {
            let text = Binding {
                idiom.idiomItself ?? ""
            } set: {
                idiom.idiomItself = $0
                saveContext()
                AnalyticsService.shared.logEvent(.idiomChanged)
            }
            TextField("Idiom", text: text, axis: .vertical)
                .textFieldStyle(.plain)
                .font(.system(.headline, design: .rounded))
                .focused($isIdiomInputFocused)
                .onSubmit {
                    isIdiomInputFocused = false
                    saveContext()
                    AnalyticsService.shared.logEvent(.idiomChanged)
                }
                .clippedWithPaddingAndBackground()
        } headerTrailingContent: {
            if isIdiomInputFocused {
                SectionHeaderButton("Save") {
                    isIdiomInputFocused = false
                    saveContext()
                    AnalyticsService.shared.logEvent(.idiomChanged)
                }
            } else {
                SectionHeaderButton("Listen", systemImage: "speaker.wave.2.fill") {
                    play(text: idiom.idiomItself)
                    AnalyticsService.shared.logEvent(.idiomPlayed)
                }
            }
        }
    }

    private var definitionSectionView: some View {
        CustomSectionView(header: "Definition") {
            let text = Binding {
                idiom.definition ?? ""
            } set: {
                idiom.definition = $0
                saveContext()
                AnalyticsService.shared.logEvent(.idiomDefinitionChanged)
            }
            TextField("Definition", text: text, axis: .vertical)
                .textFieldStyle(.plain)
                .focused($isDefinitionFieldFocused)
                .onSubmit {
                    isDefinitionFieldFocused = false
                    saveContext()
                    AnalyticsService.shared.logEvent(.idiomDefinitionChanged)
                }
                .clippedWithPaddingAndBackground()
        } headerTrailingContent: {
            if isDefinitionFieldFocused {
                SectionHeaderButton("Save") {
                    isDefinitionFieldFocused = false
                    saveContext()
                    AnalyticsService.shared.logEvent(.idiomDefinitionChanged)
                }
            } else {
                SectionHeaderButton("Listen", systemImage: "speaker.wave.2.fill") {
                    play(text: idiom.definition)
                    AnalyticsService.shared.logEvent(.idiomDefinitionPlayed)
                }
            }
        }
    }

    @ViewBuilder
    private var examplesSectionView: some View {
        let examples = idiom.examplesDecoded ?? []
        CustomSectionView(header: "Examples") {
            FormWithDivider {
                ForEach(Array(examples.enumerated()), id: \.offset) { index, example in
                    Text(example)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .clippedWithPaddingAndBackground()
                        .contextMenu {
                            Button {
                                play(text: example)
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
                                    withAnimation {
                                        removeExample(at: index)
                                    }
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
                            AnalyticsService.shared.logEvent(.idiomAddExampleTapped)
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

    // MARK: - Helper Functions

    private func saveContext() {
        do {
            try CoreDataService.shared.saveContext()
        } catch {
            print("❌ Failed to save context: \(error)")
        }
    }

    private func play(text: String?) {
        Task {
            if let text = text {
                do {
                    try await ServiceManager.shared.ttsPlayer.play(text)
                } catch {
                    print("❌ Failed to play text: \(error)")
                }
            }
        }
    }

    private func addExample(_ text: String) {
        guard !text.isEmpty else { return }
        var currentExamples = idiom.examplesDecoded
        currentExamples.append(text)
        try? idiom.updateExamples(currentExamples)
        saveContext()
        AnalyticsService.shared.logEvent(.idiomExampleAdded)
    }

    private func updateExample(at index: Int, text: String) {
        guard !text.isEmpty else { return }
        var currentExamples = idiom.examplesDecoded
        currentExamples[index] = text
        try? idiom.updateExamples(currentExamples)
        saveContext()
        AnalyticsService.shared.logEvent(.idiomExampleUpdated)
    }

    private func removeExample(at index: Int) {
        var currentExamples = idiom.examplesDecoded
        currentExamples.remove(at: index)
        try? idiom.updateExamples(currentExamples)
        saveContext()
        AnalyticsService.shared.logEvent(.idiomExampleRemoved)
    }

    private func deleteIdiom() {
        CoreDataService.shared.context.delete(idiom)
        saveContext()
        dismiss()
        AnalyticsService.shared.logEvent(.idiomRemoved)
    }
}
