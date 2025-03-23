import SwiftUI
import CoreUserInterface
import CoreNavigation
import Core
import struct Services.AnalyticsService

public struct WordDetailsContentView: PageView {

    public typealias ViewModel = WordDetailsViewModel

    @ObservedObject public var viewModel: ViewModel
    @FocusState private var isDefinitionFocused: Bool
    @FocusState private var isAddExampleFocused: Bool

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
                        AnalyticsService.shared.logEvent(.listenToWordTapped)
                    } label: {
                        Image(systemName: "speaker.wave.2.fill")
                    }
                }
            } header: {
                Text("Phonetics")
            }

            Section {
                Text(viewModel.word.partOfSpeech.rawValue)
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
                TextField("Definition", text: $viewModel.definitionTextFieldStr, axis: .vertical)
                    .focused($isDefinitionFocused)
            } header: {
                HStack {
                    Text("Definition")
                        .frame(maxWidth: .infinity, alignment: .leading)
                    if isDefinitionFocused {
                        Button {
                            UIApplication.shared.endEditing()
                            AnalyticsService.shared.logEvent(.definitionChanged)
                        } label: {
                            Text("Done")
                        }
                    }
                }
            } footer: {
                Button {
                    viewModel.handle(.speak(viewModel.word.definition))
                    AnalyticsService.shared.logEvent(.listenToDefinitionTapped)
                } label: {
                    Image(systemName: "speaker.wave.2.fill")
                    Text("Listen")
                }
                .foregroundColor(.accentColor)
            }

            Section {
                ForEach(viewModel.word.examples, id: \.self) { example in
                    Text(example)
                }
                .onDelete {
                    viewModel.handle(.removeExample($0))
                }

                if viewModel.isShowAddExample {
                    TextField("Type an example here", text: $viewModel.exampleTextFieldStr, axis: .vertical)
                        .onSubmit {
                            viewModel.handle(.addExample)
                        }
                        .submitLabel(.done)
                        .focused($isAddExampleFocused)
                } else {
                    Button {
                        withAnimation {
                            viewModel.handle(.toggleShowAddExample)
                        }
                    } label: {
                        Text("Add example")
                    }
                }
            } header: {
                HStack {
                    Text("Examples")
                        .frame(maxWidth: .infinity, alignment: .leading)
                    if isAddExampleFocused {
                        Button {
                            UIApplication.shared.endEditing()
                            viewModel.handle(.addExample)
                        } label: {
                            Text("Done")
                        }
                    }
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
    }
}
