import SwiftUI
import CoreUserInterface
import CoreNavigation
import Core
import struct Services.AnalyticsService

public struct IdiomDetailsContentView: PageView {

    public typealias ViewModel = IdiomDetailsViewModel

    @ObservedObject public var viewModel: ViewModel
    @FocusState private var isDefinitionFocused: Bool
    @FocusState private var isAddExampleFocused: Bool

    public init(viewModel: IdiomDetailsViewModel) {
        self.viewModel = viewModel
    }

    public var contentView: some View {
        List {
            Section {
                Text(viewModel.idiom.idiom)
                    .font(.system(.headline, design: .rounded))
            } header: {
                Text("Idiom")
            } footer: {
                Button {
                    viewModel.handle(.speak(viewModel.idiom.idiom))
                } label: {
                    Image(systemName: "speaker.wave.2.fill")
                    Text("Listen")
                }
                .foregroundColor(.accentColor)
            }

            Section {
                TextEditor(text: $viewModel.definitionTextFieldStr)
                    .frame(height: 150)
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
                    viewModel.handle(.speak(viewModel.idiom.definition))
                } label: {
                    Image(systemName: "speaker.wave.2.fill")
                    Text("Listen")
                }
                .foregroundColor(.accentColor)
            }

            Section {
                ForEach(viewModel.idiom.examples, id: \.self) { example in
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
                    viewModel.handle(.deleteIdiom)
                } label: {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
            }
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    viewModel.handle(.toggleFavorite)
                } label: {
                    Image(systemName: viewModel.idiom.isFavorite
                          ? "heart.fill"
                          : "heart"
                    )
                }
            }
        }
    }
}
