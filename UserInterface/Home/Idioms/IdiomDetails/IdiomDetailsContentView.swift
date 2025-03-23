import SwiftUI
import CoreUserInterface
import CoreNavigation
import Core
import struct Services.AnalyticsService

public struct IdiomDetailsContentView: PageView {

    public typealias ViewModel = IdiomDetailsViewModel

    @ObservedObject public var viewModel: ViewModel
    @FocusState private var isIdiomInputFocused: Bool
    @FocusState private var isDefinitionFocused: Bool
    @FocusState private var isAddExampleFocused: Bool
    @State private var isAddingExample = false
    @State private var editingExampleIndex: Int?
    @State private var exampleTextFieldStr = ""

    public init(viewModel: IdiomDetailsViewModel) {
        self.viewModel = viewModel
    }

    public var contentView: some View {
        ScrollView {
            LazyVStack(spacing: 24) {
                idiomSectionView
                definitionSectionView
                examplesSectionView
            }
            .padding(vertical: 12, horizontal: 16)
            .animation(.default, value: viewModel.idiom)
        }
        .background(Color.background)
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
        .alert("Edit example", isPresented: .constant(editingExampleIndex != nil), presenting: editingExampleIndex) { index in
            TextField("Example", text: $exampleTextFieldStr)
            Button("Cancel", role: .cancel) {

            }
            Button("Save") {
                viewModel.handle(.updateExample(at: index, text: exampleTextFieldStr))
                editingExampleIndex = nil
                exampleTextFieldStr = .empty
            }
        }
    }

    private var idiomSectionView: some View {
        CustomSectionView(header: "Idiom") {
            TextField("Idiom", text: $viewModel.idiom.idiom, axis: .vertical)
                .font(.system(.headline, design: .rounded))
                .focused($isIdiomInputFocused)
                .clippedWithPaddingAndBackground(.surface)
        } headerTrailingContent: {
            if isIdiomInputFocused {
                SectionHeaderButton("Done") {
                    isIdiomInputFocused = false
                    AnalyticsService.shared.logEvent(.idiomChanged)
                }
            } else {
                SectionHeaderButton("Listen", systemImage: "speaker.wave.2.fill") {
                    viewModel.handle(.play(viewModel.idiom.idiom))
                }
            }
        }
    }

    private var definitionSectionView: some View {
        CustomSectionView(header: "Definition") {
            TextField("Definition", text: $viewModel.idiom.definition, axis: .vertical)
                .focused($isDefinitionFocused)
                .clippedWithPaddingAndBackground(.surface)
        } headerTrailingContent: {
            if isDefinitionFocused {
                SectionHeaderButton("Done") {
                    isDefinitionFocused = false
                    AnalyticsService.shared.logEvent(.definitionChanged)
                }
            } else {
                SectionHeaderButton("Listen", systemImage: "speaker.wave.2.fill") {
                    viewModel.handle(.play(viewModel.idiom.definition))
                }
            }
        }
    }

    private var examplesSectionView: some View {
        CustomSectionView(header: "Examples") {
            FormWithDivider {
                ForEach(Array(viewModel.idiom.examples.enumerated()), id: \.offset) { index, example in
                    Text(example)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(vertical: 12, horizontal: 16)
                        .background(.surface)
                        .contextMenu {
                            Button {
                                exampleTextFieldStr = example
                                editingExampleIndex = index
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            Button(role: .destructive) {
                                viewModel.handle(.removeExample(at: index))
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
                if isAddingExample {
                    HStack {
                        TextField("Type an example here", text: $exampleTextFieldStr, axis: .vertical)
                            .focused($isAddExampleFocused)

                        if isAddExampleFocused {
                            Button {
                                viewModel.handle(.addExample(exampleTextFieldStr))
                                isAddingExample = false
                                exampleTextFieldStr = .empty
                            } label: {
                                Image(systemName: "checkmark.rectangle.portrait.fill")
                            }
                        }
                    }
                    .padding(vertical: 12, horizontal: 16)
                } else {
                    Button("Add example", systemImage: "plus") {
                        withAnimation {
                            isAddingExample.toggle()
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(vertical: 12, horizontal: 16)
                }
            }
            .clippedWithBackground(.surface)
        }
    }
}
