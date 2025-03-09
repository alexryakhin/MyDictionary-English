import SwiftUI
import CoreUserInterface
import CoreNavigation
import Core

public struct AddWordContentView: PageView {

    public typealias ViewModel = AddWordViewModel

    @ObservedObject public var viewModel: ViewModel

    public init(viewModel: AddWordViewModel) {
        self.viewModel = viewModel
    }

    public var contentView: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    FormWithDivider {
                        wordCellView
                        definitionCellView
                        partOfSpeechCellView
                        phoneticsCellView
                    }
                    .background(Color.surfaceBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)

                    definitionsSectionView
                }
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
            CustomTextField("Type a word", text: $viewModel.inputWord, submitLabel: .search) {
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
                    viewModel.handle(.speakInputWord)
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
        if viewModel.definitions.isNotEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("Select a definition")
                    .font(.callout)
                    .bold()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.top, 16)

                ForEach(Array(viewModel.definitions.enumerated()), id: \.offset) { offset, definition in
                    FormWithDivider {
                        CellWrapper("Definition \(offset + 1), \(definition.partOfSpeech.rawValue)") {
                            Text(definition.text)
                                .multilineTextAlignment(.leading)
                                .foregroundColor(.primary)
                        } trailingContent: {
                            checkboxImage(definition.id)
                                .onTap {
                                    definitionSelected(definition)
                                }
                        }
                        .onTapGesture {
                            definitionSelected(definition)
                        }
                        ForEach(definition.examples, id: \.self) { example in
                            CellWrapper("Example") {
                                Text(example)
                            }
                        }
                    }
                    .background(Color.surfaceBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal, 16)
                }
            }
        }
    }

    @ViewBuilder
    private func checkboxImage(_ currentId: UUID) -> some View {
        let isSelected = currentId == viewModel.selectedDefinition?.id
        Image(systemName: isSelected ? "checkmark.square.fill" : "square")
            .frame(sideLength: 20)
    }

    private func definitionSelected(_ definition: WordDefinition) {
        viewModel.handle(.selectDefinition(definition))
        UIApplication.shared.endEditing()
    }
}
