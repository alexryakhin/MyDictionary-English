import SwiftUI
import CoreUserInterface
import CoreNavigation
import Core

public struct SpellingQuizContentView: PageView {

    public typealias ViewModel = SpellingQuizViewModel

    @ObservedObject public var viewModel: ViewModel

    private var incorrectMessage: String {
        guard let randomWord = viewModel.randomWord else { return "" }

        if viewModel.attemptCount > 2 {
            return "Your word is '\(randomWord.word.trimmed)'. Try harder :)"
        } else {
            return "Incorrect. Try again"
        }
    }

    public init(viewModel: SpellingQuizViewModel) {
        self.viewModel = viewModel
    }

    public var contentView: some View {
        if let randomWord = viewModel.randomWord {
            List {
                Section {
                    Text(randomWord.definition)
                } header: {
                    Text("Definition")
                } footer: {
                    Text("Guess the word and then spell it correctly in a text field below")
                }

                Section {
                    HStack {
                        TextField("Type here", text: $viewModel.answerTextField, onCommit: {
                            withAnimation {
                                viewModel.handle(.confirmAnswer)
                            }
                        })
                        Spacer()
                        Text(randomWord.partOfSpeech.rawValue).foregroundColor(.secondary)
                    }
                } footer: {
                    Text(viewModel.isCorrectAnswer ? "" : incorrectMessage)
                }

                Section {
                    Button {
                        withAnimation {
                            viewModel.handle(.confirmAnswer)
                        }
                    } label: {
                        Text("Confirm answer")
                    }
                    .disabled(viewModel.answerTextField.isEmpty)
                }
            }
            .listStyle(.insetGrouped)
        } else {
            EmptyListView(
                label: "Congratulations!",
                description: "You got all your words!"
            ) {
                Button("Go back") {
                    viewModel.handle(.dismiss)
                }
            }
        }
    }
}
