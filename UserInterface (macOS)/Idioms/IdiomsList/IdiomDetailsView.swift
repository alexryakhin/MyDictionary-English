import SwiftUI
import Core
import CoreUserInterface__macOS_
import Shared

struct IdiomDetailsView: PageView {

    typealias ViewModel = IdiomsViewModel

    var _viewModel: StateObject<ViewModel>
    var viewModel: ViewModel {
        _viewModel.wrappedValue
    }

    @State private var isEditing = false

    init(viewModel: StateObject<ViewModel>) {
        self._viewModel = viewModel
    }

    var contentView: some View {
        VStack {
            title
            content
        }
        .padding(16)
        .navigationTitle(viewModel.selectedIdiom?.idiom ?? "")
        .toolbar {
            Button(role: .destructive) {
                viewModel.deleteCurrentIdiom()
            } label: {
                Image(systemName: "trash")
            }

            Button {
                viewModel.toggleFavorite()
            } label: {
                Image(systemName: "\(viewModel.selectedIdiom?.isFavorite == true ? "heart.fill" : "heart")")
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
            Text(viewModel.selectedIdiom?.idiom ?? "")
                .font(.title)
                .bold()
                .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                viewModel.speak(viewModel.selectedIdiom?.idiom)
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
                    TextEditor(text: _viewModel.projectedValue.definitionTextFieldStr)
                        .padding(1)
                        .background(Color.secondary.opacity(0.4))
                } else {
                    Text("Definition: ").bold()
                    + Text(viewModel.selectedIdiom?.definition ?? "")
                }
                Spacer()
                Button {
                    viewModel.speak(viewModel.selectedIdiom?.definition)
                } label: {
                    Image(systemName: "speaker.wave.2.fill")
                }
            }

            Divider()

            VStack(alignment: .leading) {
                let examples = viewModel.selectedIdiom?.examples ?? []
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
                    TextField("Type an example here", text: _viewModel.projectedValue.exampleTextFieldStr, onCommit: {
                        viewModel.saveExample()
                    })
                    .textFieldStyle(.roundedBorder)
                }
            }
        }
    }
}
