import SwiftUI

struct AddWordContentView: View {

    typealias ViewModel = AddWordViewModel

    @ObservedObject var viewModel: ViewModel

    init(viewModel: AddWordViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 24) {
                    FormWithDivider {
                        wordCellView
                        definitionCellView
                        partOfSpeechCellView
                        phoneticsCellView
                    }
                    .clippedWithBackground(.surface)

                    definitionsSectionView
                }
                .padding(.horizontal, 16)
                .editModeDisabling()
            }
            .background {
                Color.background.ignoresSafeArea()
            }
            .navigationBarTitle("Add new word")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.handle(.save)
                    } label: {
                        Text("Save")
                            .font(.system(.headline, design: .rounded))
                    }
                }
            }
            .editModeDisabling()
        }
    }

    var wordCellView: some View {
        CellWrapper("Word") {
            CustomTextField("Type a word", text: $viewModel.inputWord, submitLabel: .search, axis: .horizontal) {
                if viewModel.inputWord.isNotEmpty && viewModel.inputWord.isCorrect {
                    viewModel.handle(.fetchData)
                }
            }
            .autocorrectionDisabled()
        }
    }

    var definitionCellView: some View {
        CellWrapper("Definition") {
            CustomTextField("Enter definition", text: $viewModel.descriptionField)
                .autocorrectionDisabled()
        }
    }

    @ViewBuilder
    var partOfSpeechCellView: some View {
        CellWrapper("Part of speech") {
            Menu {
                ForEach(PartOfSpeech.allCases, id: \.self) { partOfSpeech in
                    Button {
                        viewModel.handle(.selectPartOfSpeech(partOfSpeech))
                    } label: {
                        if viewModel.partOfSpeech == partOfSpeech {
                            Image(systemName: "checkmark")
                        }
                        Text(partOfSpeech.rawValue)
                    }
                }
            } label: {
                Text(viewModel.partOfSpeech?.rawValue ?? "Select a value")
            }
        }
    }

    @ViewBuilder
    var phoneticsCellView: some View {
        if let pronunciation = viewModel.pronunciation {
            CellWrapper("Pronunciation") {
                Text(pronunciation)
            } trailingContent: {
                Button {
                    viewModel.handle(.playInputWord)
                } label: {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.title3)
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }

    @ViewBuilder
    var definitionsSectionView: some View {
        CustomSectionView(header: "Select a definition") {
            switch viewModel.status {
            case .loading:
                LazyVStack {
                    ForEach(0..<3) { _ in
                        ShimmerView(height: 100)
                    }
                }
            case .error:
                EmptyListView(
                    description: "There is an error loading definitions. Please try again.",
                    background: .clear,
                    actions: {
                        Button {
                            viewModel.handle(.fetchData)
                        } label: {
                            Label("Retry", systemImage: "magnifyingglass")
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(!viewModel.inputWord.isValidEnglishWordOrPhrase)
                    }
                )
                .clippedWithPaddingAndBackground(.surface)
            case .ready:
                ForEach(Array(viewModel.definitions.enumerated()), id: \.element.id) { offset, definition in
                    FormWithDivider {
                        CellWrapper("Definition \(offset + 1), \(definition.partOfSpeech.rawValue)") {
                            Text(definition.text)
                                .multilineTextAlignment(.leading)
                                .foregroundColor(.primary)
                        } trailingContent: {
                            checkboxImage(definition.id)
                                .onTap {
                                    definitionSelected(definition, index: offset)
                                }
                        }
                        .onTapGesture {
                            definitionSelected(definition, index: offset)
                        }
                        ForEach(definition.examples, id: \.self) { example in
                            CellWrapper("Example") {
                                Text(example)
                            }
                        }
                    }
                    .clippedWithBackground(.surface)
                }
            case .blank:
                EmptyListView(
                    description: "Type a word and press 'Search' to find its definitions",
                    background: .clear,
                    actions: {
                        Button {
                            viewModel.handle(.fetchData)
                        } label: {
                            Label("Search", systemImage: "magnifyingglass")
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(!viewModel.inputWord.isValidEnglishWordOrPhrase)
                    }
                )
                .clippedWithPaddingAndBackground(.surface)
            }
        }
    }

    @ViewBuilder
    private func checkboxImage(_ currentId: String) -> some View {
        let isSelected = currentId == viewModel.selectedDefinition?.id
        Image(systemName: isSelected ? "checkmark.square.fill" : "square")
            .frame(sideLength: 20)
    }

    private func definitionSelected(_ definition: WordDefinition, index: Int) {
        viewModel.handle(.selectDefinition(definition))
        HapticManager.shared.triggerSelection()
        UIApplication.shared.endEditing()
        AnalyticsService.shared.logEvent(.definitionSelected)
    }
}
