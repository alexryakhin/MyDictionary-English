import SwiftUI
import Core
import CoreUserInterface__macOS_
import Services

struct WordDetailsView: PageView {

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

    public var contentView: some View {
        ScrollViewWithCustomNavBar {
            LazyVStack(spacing: 24) {
                transcriptionSectionView
                partOfSpeechSectionView
                definitionSectionView
                examplesSectionView
            }
            .padding(vertical: 12, horizontal: 16)
        } navigationBar: {
            if let selectedWord = viewModel.selectedWord {
                Text(selectedWord.word)
                    .font(.largeTitle)
                    .bold()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(vertical: 12, horizontal: 16)
                    .padding(.top, 24)
            }
        }
        .background(Color.backgroundColor)
        .toolbar {
            Button(role: .destructive) {
                viewModel.handle(.deleteCurrentWord)
            } label: {
                Image(systemName: "trash")
                    .foregroundStyle(.red)
            }

            Button {
                viewModel.handle(.toggleFavorite)
            } label: {
                Image(systemName: "\(viewModel.selectedWord?.isFavorite == true ? "heart.fill" : "heart")")
                    .foregroundColor(.accentColor)
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
                .clippedWithPaddingAndBackground(.surfaceColor)
        } headerTrailingContent: {
            if isPhoneticsFocused {
                SectionHeaderButton("Done") {
                    isPhoneticsFocused = false
                    viewModel.handle(.updateCDWord)
                }
            } else {
                SectionHeaderButton("Listen", systemImage: "speaker.wave.2.fill") {
                    viewModel.handle(.play(viewModel.selectedWord?.word))
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
                    } label: {
                        Text(partCase.rawValue)
                        if viewModel.selectedWord?.partOfSpeech == partCase {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            } label: {
                Text(viewModel.selectedWord?.partOfSpeech.rawValue ?? "")
            }
            .buttonStyle(.borderless)
            .frame(maxWidth: .infinity, alignment: .leading)
            .clippedWithPaddingAndBackground(.surfaceColor)
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
                .clippedWithPaddingAndBackground(.surfaceColor)
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
            let examples = viewModel.selectedWord?.examples ?? []
            FormWithDivider {
                ForEach(Array(examples.enumerated()), id: \.offset) { index, example in
                    Text(example)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(vertical: 12, horizontal: 16)
                        .background(Color.surfaceColor)
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
            .clippedWithBackground(.surfaceColor)
        }
    }
}
