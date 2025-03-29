import SwiftUI
import Core
import CoreUserInterface__macOS_
import Shared

struct IdiomDetailsView: PageView {

    typealias ViewModel = IdiomDetailsViewModel

    var viewModel: StateObject<ViewModel>
    @State private var isEditing = false

    init(idiom: Idiom) {
        viewModel = StateObject(wrappedValue: IdiomDetailsViewModel(idiom: idiom))
    }

    var contentView: some View {
        VStack {
            title
            content
        }
        .padding(16)
        .navigationTitle(viewModel.wrappedValue.idiom.idiom)
        .toolbar {
            Button(role: .destructive) {
                viewModel.wrappedValue.deleteCurrentIdiom()
            } label: {
                Image(systemName: "trash")
            }

            Button {
                viewModel.wrappedValue.toggleFavorite()
            } label: {
                Image(systemName: "\(viewModel.wrappedValue.idiom.isFavorite == true ? "heart.fill" : "heart")")
                    .foregroundColor(.accentColor)
            }

            Button(isEditing ? "Save" : "Edit") {
                isEditing.toggle()
            }
        }
    }

    // MARK: - Title

    private var title: some View {
        HStack {
            Text(viewModel.wrappedValue.idiom.idiom)
                .font(.title)
                .bold()
                .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                viewModel.wrappedValue.speak(viewModel.wrappedValue.idiom.idiom)
            } label: {
                Image(systemName: "speaker.wave.2.fill")
            }
        }
    }

    // MARK: - Primary Content

    private var content: some View {
        ScrollView {
            HStack {
                if isEditing {
                    Text("Definition: ").bold()
                    TextEditor(text: viewModel.projectedValue.definitionTextFieldStr)
                        .padding(1)
                        .background(Color.secondary.opacity(0.4))
                } else {
                    Text("Definition: ").bold()
                    + Text(viewModel.wrappedValue.idiom.definition)
                }
                Spacer()
                Button {
                    viewModel.wrappedValue.speak(viewModel.wrappedValue.idiom.definition)
                } label: {
                    Image(systemName: "speaker.wave.2.fill")
                }
            }

            Divider()

            VStack(alignment: .leading) {
                let examples = viewModel.wrappedValue.idiom.examples
                HStack {
                    Text("Examples:").bold()
                    Spacer()
                    if !examples.isEmpty {
                        Button {
                            withAnimation {
                                viewModel.wrappedValue.isShowAddExample = true
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
                                    viewModel.wrappedValue.removeExample(atIndex: offset)
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
                                viewModel.wrappedValue.isShowAddExample = true
                            }
                        } label: {
                            Text("Add example")
                        }
                    }
                }

                if viewModel.wrappedValue.isShowAddExample {
                    TextField("Type an example here", text: viewModel.projectedValue.exampleTextFieldStr, onCommit: {
                        viewModel.wrappedValue.addExample()
                    })
                    .textFieldStyle(.roundedBorder)
                }
            }
        }
    }
}
