import SwiftUI
import Core
import CoreUserInterface__macOS_

struct WordDetailsView: View {
    @ObservedObject var viewModel: WordsViewModel
    @State private var isEditing = false

    var body: some View {
        VStack {
            title
            content
        }
        .padding(16)
        .navigationTitle(viewModel.selectedWord?.word ?? "")
        .toolbar {
            Button(role: .destructive) {
                viewModel.deleteCurrentWord()
            } label: {
                Image(systemName: "trash")
            }

            Button {
                viewModel.toggleFavorite()
            } label: {
                Image(systemName: "\(viewModel.selectedWord?.isFavorite == true ? "heart.fill" : "heart")")
                    .foregroundColor(.accentColor)
            }

            Button(isEditing ? "Save" : "Edit") {
                isEditing.toggle()
            }
        }
    }

    // MARK: - Title

    private var title: some View {
        Text(viewModel.selectedWord?.word ?? "")
            .font(.title)
            .bold()
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Primary Content

    private var content: some View {
        ScrollView {
            HStack {
                Text("Phonetics: ").bold()
                + Text("[\(viewModel.selectedWord?.phonetic ?? "No transcription")]")
                Spacer()
                Button {
                    viewModel.speak(viewModel.selectedWord?.word)
                } label: {
                    Image(systemName: "speaker.wave.2.fill")
                }
            }

            Divider()

            HStack {
                if !isEditing {
                    Text("Part Of Speech: ").bold()
                    + Text(viewModel.selectedWord?.partOfSpeech.rawValue ?? "")
                } else {
                    Picker(selection: Binding(get: {
                        viewModel.selectedWord?.partOfSpeech ?? .unknown
                    }, set: { newValue in
                        viewModel.changePartOfSpeech(newValue)
                    }), label: Text("Part of Speech").bold()) {
                        ForEach(PartOfSpeech.allCases, id: \.self) { partCase in
                            Text(partCase.rawValue)
                                .tag(partCase.rawValue)
                        }
                    }
                }
                Spacer()
            }

            Divider()

            HStack {
                if isEditing {
                    Text("Definition: ").bold()
                    TextField("Definition", text: $viewModel.definitionTextFieldStr)
                        .textFieldStyle(.roundedBorder)
                } else {
                    Text("Definition: ").bold()
                    + Text(viewModel.selectedWord?.definition ?? "")
                }
                Spacer()
                Button {
                    viewModel.speak(viewModel.selectedWord?.definition)
                } label: {
                    Image(systemName: "speaker.wave.2.fill")
                }
            }

            Divider()

            VStack(alignment: .leading) {
                let examples = viewModel.selectedWord?.examples ?? []
                HStack {
                    Text("Examples:").bold()
                    Spacer()
                    if !examples.isEmpty {
                        Button {
                            withAnimation {
                                viewModel.isShowAddExample = true
                            }
                        } label: {
                            Text("Add example")
                        }
                    }
                }

                if !examples.isEmpty {
                    ForEach(Array(examples.enumerated()), id: \.offset) { offset, element in
                        if !isEditing {
                            Text("\(offset + 1). \(examples[offset])")
                        } else {
                            HStack {
                                Button {
                                    viewModel.removeExample(atIndex: offset)
                                } label: {
                                    Image(systemName: "trash")
                                }
                                Text("\(offset + 1). \(examples[offset])")
                            }
                        }
                    }
                } else {
                    HStack {
                        Text("No examples yet..")
                        Button {
                            withAnimation {
                                viewModel.isShowAddExample = true
                            }
                        } label: {
                            Text("Add example")
                        }
                    }
                }
                if viewModel.isShowAddExample {
                    TextField("Type an example here", text: $viewModel.exampleTextFieldStr, onCommit: {
                        withAnimation(.easeInOut) {
                            viewModel.saveExample()
                        }
                    })
                    .textFieldStyle(.roundedBorder)
                }
            }
        }
    }
}
