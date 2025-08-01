import SwiftUI

struct AddWordView: View {

    typealias ViewModel = AddWordViewModel

    @Environment(\.dismiss) var dismiss
    var _viewModel: StateObject<ViewModel>
    var viewModel: ViewModel {
        _viewModel.wrappedValue
    }

    init(inputWord: String) {
        _viewModel = StateObject(wrappedValue: ViewModel(inputWord: inputWord))
    }

    var body: some View {
        ScrollViewWithCustomNavBar {
            LazyVStack(spacing: 24) {
                FormWithDivider {
                    wordCellView
                    definitionCellView
                    partOfSpeechCellView
                    phoneticsCellView
                }
                .clippedWithBackground(.surfaceColor)

                definitionsSectionView
            }
            .padding(.horizontal, 16)
        } navigationBar: {
            HStack(spacing: 12) {
                Text("Add new word")
                    .font(.title2)
                    .bold()
                    .frame(maxWidth: .infinity, alignment: .leading)
                Button {
                    dismiss()
                    AnalyticsService.shared.logEvent(.closeAddWordTapped)
                } label: {
                    Image(systemName: "xmark.app.fill")
                        .font(.title2)
                }
                .buttonStyle(.borderless)
            }
            .padding(vertical: 12, horizontal: 16)
        }
        .safeAreaInset(edge: .bottom) {
            Button {
                viewModel.handle(.save)
                AnalyticsService.shared.logEvent(.saveWordTapped)
            } label: {
                Label("Save", systemImage: "checkmark.square.fill")
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(vertical: 8, horizontal: 16)
            }
            .buttonStyle(.borderedProminent)
            .padding(vertical: 12, horizontal: 16)
            .colorWithGradient(
                offset: 0,
                interpolation: 0.2,
                direction: .down
            )
        }
        .frame(width: 500, height: 500)
        .background(Color.backgroundColor)
        .onReceive(viewModel.dismissPublisher) { _ in
            dismiss()
        }
        .onAppear {
            AnalyticsService.shared.logEvent(.addWordOpened)
        }
    }

    var wordCellView: some View {
        CellWrapper("Word") {
            CustomTextField("Type a word", text: _viewModel.projectedValue.inputWord) {
                if viewModel.inputWord.isNotEmpty && viewModel.inputWord.isCorrect {
                    viewModel.handle(.fetchData)
                }
            }
            .autocorrectionDisabled()
        }
    }

    var definitionCellView: some View {
        CellWrapper("Definition") {
            CustomTextField("Enter definition", text: _viewModel.projectedValue.descriptionField)
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
            .buttonStyle(.borderless)
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
                    Label("Listen", systemImage: "speaker.wave.2.fill")
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
                        .disabled(!viewModel.inputWord.isValidEnglishWordOrPhrase)
                    }
                )
                .clippedWithPaddingAndBackground(.surfaceColor)
            case .ready:
                ForEach(Array(viewModel.definitions.enumerated()), id: \.element.id) { offset, definition in
                    FormWithDivider {
                        CellWrapper("Definition \(offset + 1), \(definition.partOfSpeech.rawValue)") {
                            Text(definition.text)
                                .multilineTextAlignment(.leading)
                                .foregroundColor(.primary)
                        } trailingContent: {
                            checkboxImage(definition.id)
                                .foregroundColor(.accentColor)
                        }
                        .background(Color.surfaceColor)
                        .onTapGesture {
                            definitionSelected(definition, index: offset)
                        }
                        ForEach(definition.examples, id: \.self) { example in
                            CellWrapper("Example") {
                                Text(example)
                            }
                        }
                    }
                    .clippedWithBackground(.surfaceColor)
                }
            case .blank:
                EmptyListView(
                    description: "Type a word and press enter to search for definitions.",
                    background: .clear,
                    actions: {
                        Button {
                            viewModel.handle(.fetchData)
                        } label: {
                            Label("Search", systemImage: "magnifyingglass")
                        }
                        .disabled(!viewModel.inputWord.isValidEnglishWordOrPhrase)
                    }
                )
                .clippedWithPaddingAndBackground(.surfaceColor)
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
        AnalyticsService.shared.logEvent(.definitionSelected)
    }
}
