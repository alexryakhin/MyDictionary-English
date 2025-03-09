import SwiftUI
import CoreUserInterface
import CoreNavigation
import Core

public struct ChooseDefinitionQuizContentView: PageView {

    public typealias ViewModel = ChooseDefinitionQuizViewModel

    @ObservedObject public var viewModel: ViewModel

    public init(viewModel: ChooseDefinitionQuizViewModel) {
        self.viewModel = viewModel
    }

    public var contentView: some View {
        if !viewModel.words.isEmpty {
            List {
                Section {
                    HStack {
                        Text(viewModel.correctWord.word)
                            .bold()
                        Spacer()
                        Text(viewModel.correctWord.partOfSpeech.rawValue)
                            .foregroundColor(.secondary)
                    }

                } header: {
                    Text("Given word")
                } footer: {
                    Text("Choose from the given definitions below")
                }

                Section {
                    ForEach(0..<3) { index in
                        Button {
                            viewModel.handle(.answerSelected(index))
                        } label: {
                            Text(viewModel.words[index].definition)
                                .foregroundColor(.primary)
                        }
                    }
                } footer: {
                    Text(viewModel.isCorrectAnswer ? "" : "Incorrect. Try Again")
                }
            }
            .listStyle(.insetGrouped)
        }
    }
}
