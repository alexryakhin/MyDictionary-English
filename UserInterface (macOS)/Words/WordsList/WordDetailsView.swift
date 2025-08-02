import SwiftUI

struct WordDetailsView: View {

    typealias ViewModel = WordsViewModel

    var _viewModel: StateObject<ViewModel>
    var viewModel: ViewModel {
        _viewModel.wrappedValue
    }

    @FocusState private var isPhoneticsFocused: Bool
    @FocusState private var isDefinitionFocused: Bool
    @FocusState private var isAddExampleFocused: Bool
    @State private var isAddingExample = false
    @State private var editingExampleIndex: Int?
    @State private var exampleTextFieldStr = ""

    init(viewModel: StateObject<ViewModel>) {
        self._viewModel = viewModel
    }

    var body: some View {
        VStack(spacing: 0) {
            if let selectedWord = viewModel.selectedWord {
                Text(selectedWord.wordItself ?? "")
                    .font(.largeTitle)
                    .bold()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(vertical: 12, horizontal: 16)
                    .padding(.top, 8)
                    .contextMenu {
                        Button("Copy") {
                            let pasteboard = NSPasteboard.general
                            pasteboard.declareTypes([NSPasteboard.PasteboardType.string], owner: nil)
                            pasteboard.setString(selectedWord.wordItself ?? "", forType: .string)
                        }
                    }
                Divider()
            }
            ScrollView {
                LazyVStack(spacing: 24) {
                    transcriptionSectionView
                    partOfSpeechSectionView
                    definitionSectionView
                    examplesSectionView
                }
                .padding(vertical: 12, horizontal: 16)
            }
        }
        .toolbar {
            Button(role: .destructive) {
                viewModel.handle(.deleteCurrentWord)
                AnalyticsService.shared.logEvent(.removeWordMenuButtonTapped)
            } label: {
                Image(systemName: "trash")
                    .foregroundStyle(.red)
            }

            Button {
                viewModel.handle(.toggleFavorite)
            } label: {
                Image(systemName: "\(viewModel.selectedWord?.isFavorite == true ? "heart.fill" : "heart")")
                    .foregroundColor(.accentColor)
                    .animation(.easeInOut(duration: 0.2), value: viewModel.selectedWord?.isFavorite)
            }
        }
        .alert("Edit example", isPresented: .constant(editingExampleIndex != nil), presenting: editingExampleIndex) { index in
            TextField("Example", text: $exampleTextFieldStr)
            Button("Cancel", role: .cancel) {
                AnalyticsService.shared.logEvent(.wordExampleChangingCanceled)
            }
            Button("Save") {
                viewModel.handle(.updateExample(at: index, text: exampleTextFieldStr))
                editingExampleIndex = nil
                exampleTextFieldStr = .empty
                AnalyticsService.shared.logEvent(.wordExampleChanged)
            }
        }
    }

    private var transcriptionSectionView: some View {
        CustomSectionView(header: "Transcription") {
            let text = Binding {
                viewModel.selectedWord?.phonetic ?? ""
            } set: {
                viewModel.handle(.updateTranscription(text: $0))
            }
            TextField("Transcription", text: text, axis: .vertical)
                .textFieldStyle(.plain)
                .focused($isPhoneticsFocused)
                .clippedWithPaddingAndBackground()
        } headerTrailingContent: {
            if isPhoneticsFocused {
                SectionHeaderButton("Done") {
                    isPhoneticsFocused = false
                    viewModel.handle(.updateCDWord)
                    AnalyticsService.shared.logEvent(.wordPhoneticsChanged)
                }
            } else {
                SectionHeaderButton("Listen", systemImage: "speaker.wave.2.fill") {
                    viewModel.handle(.play(viewModel.selectedWord?.wordItself))
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
                        viewModel.handle(.updatePartOfSpeech(partCase))
                        AnalyticsService.shared.logEvent(.partOfSpeechChanged)
                    } label: {
                        Text(partCase.rawValue)
                        if viewModel.selectedWord?.partOfSpeech == partCase.rawValue {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            } label: {
                Text(viewModel.selectedWord?.partOfSpeech ?? "")
            }
            .buttonStyle(.borderless)
            .frame(maxWidth: .infinity, alignment: .leading)
            .clippedWithPaddingAndBackground()
        }
    }

    private var definitionSectionView: some View {
        CustomSectionView(header: "Definition") {
            let text = Binding {
                viewModel.selectedWord?.definition ?? ""
            } set: {
                viewModel.handle(.updateDefinition(definition: $0))
            }
            TextField("Definition", text: text, axis: .vertical)
                .textFieldStyle(.plain)
                .focused($isDefinitionFocused)
                .clippedWithPaddingAndBackground()
        } headerTrailingContent: {
            if isDefinitionFocused {
                SectionHeaderButton("Done") {
                    isDefinitionFocused = false
                    viewModel.handle(.updateCDWord)
                    AnalyticsService.shared.logEvent(.wordDefinitionChanged)
                }
            } else {
                SectionHeaderButton("Listen", systemImage: "speaker.wave.2.fill") {
                    viewModel.handle(.play(viewModel.selectedWord?.definition))
                    AnalyticsService.shared.logEvent(.wordDefinitionPlayed)
                }
            }
        }
    }

    private var examplesSectionView: some View {
        CustomSectionView(header: "Examples") {
            let examples = viewModel.selectedWord?.examplesDecoded ?? []
            FormWithDivider {
                ForEach(Array(examples.enumerated()), id: \.offset) { index, example in
                    Text(example)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .clippedWithPaddingAndBackground()
                        .contextMenu {
                            Button {
                                viewModel.handle(.play(example))
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
                                    viewModel.handle(.removeExample(at: index))
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
                                viewModel.handle(.addExample(exampleTextFieldStr))
                                isAddingExample = false
                                exampleTextFieldStr = .empty
                                AnalyticsService.shared.logEvent(.wordExampleAdded)
                            } label: {
                                Image(systemName: "checkmark.rectangle.portrait.fill")
                                    .font(.title3)
                                    .foregroundColor(.accentColor)
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
}
