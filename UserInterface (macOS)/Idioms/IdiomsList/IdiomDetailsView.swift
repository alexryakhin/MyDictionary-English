import SwiftUI
import Core
import CoreUserInterface__macOS_
import Shared
import Services

struct IdiomDetailsView: PageView {

    typealias ViewModel = IdiomsViewModel

    var _viewModel: StateObject<ViewModel>
    var viewModel: ViewModel {
        _viewModel.wrappedValue
    }

    @FocusState private var isIdiomInputFocused: Bool
    @FocusState private var isDefinitionFieldFocused: Bool
    @FocusState private var isAddExampleFocused: Bool
    @State private var isAddingExample = false
    @State private var editingExampleIndex: Int?
    @State private var exampleTextFieldStr = ""

    init(viewModel: StateObject<ViewModel>) {
        self._viewModel = viewModel
    }

    var contentView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                idiomSectionView
                definitionSectionView
                examplesSectionView
            }
            .padding(vertical: 12, horizontal: 16)
        }
        .toolbar {
            Button(role: .destructive) {
                viewModel.handle(.deleteCurrentIdiom)
                AnalyticsService.shared.logEvent(.removeIdiomMenuButtonTapped)
            } label: {
                Image(systemName: "trash")
                    .foregroundStyle(.red)
            }

            Button {
                viewModel.handle(.toggleFavorite)
                AnalyticsService.shared.logEvent(.idiomFavoriteTapped)
            } label: {
                Image(systemName: "\(viewModel.selectedIdiom?.isFavorite == true ? "heart.fill" : "heart")")
                    .foregroundColor(.accentColor)
            }
        }
        .alert("Edit example", isPresented: .constant(editingExampleIndex != nil), presenting: editingExampleIndex) { index in
            TextField("Example", text: $exampleTextFieldStr)
            Button("Cancel", role: .cancel) {
                AnalyticsService.shared.logEvent(.idiomExampleChangingCanceled)
            }
            Button("Save") {
                viewModel.handle(.updateExample(at: index, text: exampleTextFieldStr))
                editingExampleIndex = nil
                exampleTextFieldStr = .empty
            }
        }
    }

    // MARK: - Primary Content

    private var idiomSectionView: some View {
        CustomSectionView(header: "Idiom") {
            let text = Binding {
                viewModel.selectedIdiom?.idiom ?? ""
            } set: {
                viewModel.handle(.updateIdiom(text: $0))
            }
            TextField("Idiom", text: text, axis: .vertical)
                .textFieldStyle(.plain)
                .font(.system(.headline, design: .rounded))
                .focused($isIdiomInputFocused)
                .onSubmit {
                    isIdiomInputFocused = false
                    viewModel.handle(.updateCDIdiom)
                    AnalyticsService.shared.logEvent(.idiomChanged)
                }
                .clippedWithPaddingAndBackground(.surfaceColor)
        } headerTrailingContent: {
            if isIdiomInputFocused {
                SectionHeaderButton("Save") {
                    isIdiomInputFocused = false
                    viewModel.handle(.updateCDIdiom)
                    AnalyticsService.shared.logEvent(.idiomChanged)
                }
            } else {
                SectionHeaderButton("Listen", systemImage: "speaker.wave.2.fill") {
                    viewModel.handle(.play(text: viewModel.selectedIdiom?.idiom))
                    AnalyticsService.shared.logEvent(.idiomPlayed)
                }
            }
        }
    }

    private var definitionSectionView: some View {
        CustomSectionView(header: "Definition") {
            let text = Binding {
                viewModel.selectedIdiom?.definition ?? ""
            } set: {
                viewModel.handle(.updateDefinition(definition: $0))
            }
            TextField("Definition", text: text, axis: .vertical)
                .textFieldStyle(.plain)
                .focused($isDefinitionFieldFocused)
                .onSubmit {
                    isDefinitionFieldFocused = false
                    viewModel.handle(.updateCDIdiom)
                    AnalyticsService.shared.logEvent(.idiomDefinitionChanged)
                }
                .clippedWithPaddingAndBackground(.surfaceColor)
        } headerTrailingContent: {
            if isDefinitionFieldFocused {
                SectionHeaderButton("Save") {
                    isDefinitionFieldFocused = false
                    viewModel.handle(.updateCDIdiom)
                    AnalyticsService.shared.logEvent(.idiomDefinitionChanged)
                }
            } else {
                SectionHeaderButton("Listen", systemImage: "speaker.wave.2.fill") {
                    viewModel.handle(.play(text: viewModel.selectedIdiom?.definition))
                    AnalyticsService.shared.logEvent(.idiomDefinitionPlayed)
                }
            }
        }
    }

    @ViewBuilder
    private var examplesSectionView: some View {
        let examples = viewModel.selectedIdiom?.examples ?? []
        CustomSectionView(header: "Examples") {
            FormWithDivider {
                ForEach(Array(examples.enumerated()), id: \.offset) { index, example in
                    Text(example)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(vertical: 12, horizontal: 16)
                        .background(Color.surfaceColor)
                        .contextMenu {
                            Button {
                                viewModel.handle(.play(text: example))
                                AnalyticsService.shared.logEvent(.idiomExamplePlayed)
                            } label: {
                                Label("Listen", systemImage: "speaker.wave.2.fill")
                            }
                            Button {
                                exampleTextFieldStr = example
                                editingExampleIndex = index
                                AnalyticsService.shared.logEvent(.idiomExampleChangeButtonTapped)
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            Section {
                                Button(role: .destructive) {
                                    withAnimation {
                                        viewModel.handle(.removeExample(at: index))
                                    }
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
                            AnalyticsService.shared.logEvent(.idiomAddExampleTapped)
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
