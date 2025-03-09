import SwiftUI
import CoreUserInterface
import CoreNavigation
import Core

public struct IdiomDetailsContentView: PageView {

    public typealias ViewModel = IdiomDetailsViewModel

    @ObservedObject public var viewModel: ViewModel

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
                    .frame(height: 200)
            } header: {
                Text("Definition")
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
                Button {
                    if !viewModel.isShowAddExample {
                        withAnimation {
                            viewModel.handle(.toggleShowAddExample)
                        }
                    } else {
                        withAnimation(.easeInOut) {
                            viewModel.handle(.addExample)
                        }
                    }
                } label: {
                    Text("Add example")
                }

                ForEach(viewModel.idiom.examples, id: \.self) { example in
                    Text(example)
                }
                .onDelete {
                    viewModel.handle(.removeExample($0))
                }

                if viewModel.isShowAddExample {
                    TextField("Type an example here", text: $viewModel.exampleTextFieldStr, onCommit: {
                        withAnimation(.easeInOut) {
                            viewModel.handle(.addExample)
                        }
                    })
                    .submitLabel(.done)
                }
            } header: {
                Text("Examples")
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
