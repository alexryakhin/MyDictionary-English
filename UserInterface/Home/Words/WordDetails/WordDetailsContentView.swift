import SwiftUI
import CoreUserInterface
import CoreNavigation
import Core

public struct WordDetailsContentView: PageView {

    public typealias ViewModel = WordDetailsViewModel

    @ObservedObject public var viewModel: ViewModel

    public init(viewModel: WordDetailsViewModel) {
        self.viewModel = viewModel
    }

    public var contentView: some View {
        List {
            Section {
                HStack {
                    Text("\(viewModel.word.phonetic?.nilIfEmpty ?? "No transcription")")
                    Spacer()
                    Button {
                        viewModel.handle(.speak(viewModel.word.word))
                    } label: {
                        Image(systemName: "speaker.wave.2.fill")
                    }
                }
            } header: {
                Text("Phonetics")
            }

            Section {
                Text(viewModel.word.partOfSpeech)
                    .contextMenu {
                        ForEach(PartOfSpeech.allCases, id: \.self) { partCase in
                            Button {
                                viewModel.handle(.updatePartOfSpeech(partCase.rawValue))
                            } label: {
                                Text(partCase.rawValue)
                            }
                        }
                    }
            } header: {
                Text("Part Of Speech")
            }

            Section {
                TextField("Definition", text: $viewModel.definitionTextFieldStr)
                    .submitLabel(.done)
            } header: {
                Text("Definition")
            } footer: {
                Button {
                    viewModel.handle(.speak(viewModel.word.definition))
                } label: {
                    Image(systemName: "speaker.wave.2.fill")
                    Text("Listen")
                }
                .foregroundColor(.accentColor)
            }
            Section {
                Button {
                    withAnimation {
                        viewModel.handle(.toggleShowAddExample)
                    }
                } label: {
                    Text("Add example")
                }

                ForEach(viewModel.word.examples, id: \.self) { example in
                    Text(example)
                }
                .onDelete {
                    viewModel.handle(.removeExample($0))
                }

                if viewModel.isShowAddExample {
                    TextField("Type an example here", text: $viewModel.exampleTextFieldStr)
                        .onSubmit {
                            viewModel.handle(.addExample)
                        }
                        .submitLabel(.done)
                }
            } header: {
                Text("Examples")
            } footer: {
                if viewModel.isShowAddExample {
                    Button {
                        viewModel.handle(.addExample)
                    } label: {
                        Image(systemName: "checkmark")
                        Text("Save")
                    }
                    .foregroundColor(.accentColor)
                }
            }
        }
        .listStyle(.insetGrouped)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    viewModel.handle(.deleteWord)
                } label: {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
            }
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    viewModel.handle(.toggleFavorite)
                } label: {
                    Image(systemName: viewModel.word.isFavorite
                          ? "heart.fill"
                          : "heart"
                    )
                }
            }
        }
        .scrollDismissesKeyboard(.interactively)
    }
}
