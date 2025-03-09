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
            .background(
                Color(.background)
                    .ignoresSafeArea()
                    .editModeDisabling()
            )
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
        var cases: [PartOfSpeech] {
//            if let result = viewModel.resultWordDetails {
//                return result.meanings
//                    .compactMap {
//                        PartOfSpeech(rawValue: $0.partOfSpeech)
//                    }
//                    .removingDuplicates(by: \.rawValue)
//            } else {
                return PartOfSpeech.allCases
//            }
        }
        CellWrapper("Part of speech") {
            Menu {
                ForEach(cases, id: \.self) { partCase in
                    Button {
                        viewModel.partOfSpeech = partCase
                    } label: {
                        if viewModel.partOfSpeech == partCase {
                            Image(systemName: "checkmark")
                        }
                        Text(partCase.rawValue)
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
                        CellWrapper("Definition \(offset + 1), \(definition.partOfSpeech?.rawValue ?? "")") {
                            Text(definition.text!.removingHTMLTags())
                                .multilineTextAlignment(.leading)
                        } onTapAction: {
                            viewModel.selectedDefinition = definition
                            UIApplication.shared.endEditing()
                        }
                        ForEach(definition.examples, id: \.self) { example in
                            CellWrapper("Example") {
                                Text(example)
                            }
                        }
//                        if element.synonyms.isNotEmpty {
//                            CellWrapper("Synonyms") {
//                                Text(element.synonyms.joined(separator: ", "))
//                            }
//                        }
//                        if element.antonyms.isNotEmpty {
//                            CellWrapper("Antonyms") {
//                                Text(element.antonyms.joined(separator: ", "))
//                            }
//                        }
                    }
                    .background(Color.surfaceBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal, 16)
                }
            }
        }
    }
}
