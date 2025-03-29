import SwiftUI

struct AddWordView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel: AddWordViewModel
    @State private var wordClassSelection = 0

    init(inputWord: String) {
        _viewModel = StateObject(wrappedValue: AddWordViewModel(inputWord: inputWord))
    }

    var body: some View {
        VStack {
            HStack {
                Text("Add new word").font(.title2).bold()
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Text("Close")
                }
            }
            HStack {
                TextField("Enter the word", text: $viewModel.inputWord, onCommit: {
                    viewModel.fetchData()
                })
                .textFieldStyle(.roundedBorder)

                Button {
                    viewModel.fetchData()
                } label: {
                    Text("Get definitions")
                }
            }
            TextField("Enter definition", text: $viewModel.descriptionField)
                .textFieldStyle(.roundedBorder)

//            if viewModel.resultWordDetails == nil {
//                Picker(selection: $viewModel.partOfSpeech, label: Text("Part of Speech")) {
//                    ForEach(PartOfSpeech.allCases, id: \.self) { partCase in
//                        Text(partCase.rawValue)
//                    }
//                }
//            }

//            if viewModel.resultWordDetails != nil && viewModel.status == .ready {
//                VStack {
//                    Picker(selection: $wordClassSelection, label: Text("Part of Speech")) {
//                        ForEach(viewModel.resultWordDetails!.meanings.indices, id: \.self) { index in
//                            Text("\(viewModel.resultWordDetails!.meanings[index].partOfSpeech)")
//                        }
//                    }
//                    .onChange(of: wordClassSelection) { newValue in
//                        if let value = viewModel.resultWordDetails?.meanings[newValue].partOfSpeech {
//                            viewModel.partOfSpeech = .init(rawValue: value) ?? .unknown
//                        }
//                    }
//
//                    if viewModel.resultWordDetails!.phonetic != nil {
//                        HStack(spacing: 0) {
//                            Text("Phonetic: ").bold()
//                            Text(viewModel.resultWordDetails!.phonetic ?? "")
//                            Spacer()
//                            Button {
//                                viewModel.speakInputWord()
//                            } label: {
//                                Image(systemName: "speaker.wave.2.fill")
//                            }
//                        }
//                    }
//
//                    TabView {
//                        ForEach(viewModel.resultWordDetails!.meanings[wordClassSelection].definitions.indices, id: \.self) { index in
//                            ScrollView {
//                                VStack(alignment: .leading) {
//                                    if !definitions[index].definition.isEmpty {
//                                        Divider()
//                                        HStack {
//                                            Text("Definition \(index + 1): ").bold()
//                                            + Text(definitions[index].definition)
//                                        }
//                                        .onTapGesture {
//                                            viewModel.descriptionField = definitions[index].definition
//                                        }
//                                    }
//                                    if definitions[index].example != nil {
//                                        Divider()
//                                        Text("Example: ").bold()
//                                        + Text(definitions[index].example!)
//                                    }
//                                    if !definitions[index].synonyms.isEmpty {
//                                        Divider()
//                                        Text("Synonyms: ").bold()
//                                        + Text(definitions[index].synonyms.joined(separator: ", "))
//                                    }
//                                    if !definitions[index].antonyms.isEmpty {
//                                        Divider()
//                                        Text("Antonyms: ").bold()
//                                        + Text(definitions[index].antonyms.joined(separator: ", "))
//                                    }
//                                }
//                            }
//                            .tabItem {
//                                Text("\(index + 1)")
//                            }
//                            .padding(.horizontal)
//                        }
//                    }
//                }
//            } else if viewModel.status == .loading {
//                VStack {
//                    Spacer().frame(height: 50)
//                    ProgressView()
//                    Spacer()
//                }
//            } else {
//                Spacer()
//            }

            Button {
                viewModel.saveWord()
                if !viewModel.showingAlert {
                    dismiss()
                }
            } label: {
                Text("Save")
                    .bold()
            }
        }
        .frame(width: 600, height: 500)
        .padding(16)
        .alert(isPresented: $viewModel.showingAlert) {
            Alert(
                title: Text("Ooops..."),
                message: Text("You should enter a word and its definition before saving it"),
                dismissButton: .default(Text("Got it"))
            )
        }
    }
}
