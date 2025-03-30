import SwiftUI
import Core
import CoreUserInterface__macOS_
import Shared

struct SpellingQuizView: PageView {

    typealias ViewModel = SpellingQuizViewModel

    var _viewModel: StateObject<ViewModel>
    var viewModel: ViewModel {
        _viewModel.wrappedValue
    }

    init(viewModel: StateObject<ViewModel>) {
        self._viewModel = viewModel
    }

    private var incorrectMessage: String {
        guard let randomWord = viewModel.randomWord else { return "" }

        if viewModel.attemptCount > 2 {
            return "Your word is '\(randomWord.word.trimmed)'. Try harder :)"
        } else {
            return "Incorrect. Try again"
        }
    }

    var contentView: some View {
        VStack {
            Spacer().frame(height: 100)

            Text(viewModel.randomWord?.definition ?? "Error")
                .font(.title)
                .bold()
                .padding(.horizontal, 30)
                .multilineTextAlignment(.center)

            Text(viewModel.randomWord?.partOfSpeech.rawValue ?? "error")
                .foregroundColor(.secondary)

            Spacer()

            VStack {
                Text("Guess the word and then spell it correctly in a text field below")
                    .foregroundColor(.secondary).font(.caption)

                HStack {
                    TextField("Answer", text: _viewModel.projectedValue.answerTextField, onCommit: {
                        viewModel.confirmAnswer()
                    })
                    .frame(maxWidth: 300)
                    .multilineTextAlignment(.center)
                    .textFieldStyle(.plain)
                }
                .padding(.vertical, 8)
                .padding(.horizontal)
                .background(Color.primary.opacity(0.15))
                .cornerRadius(8)
                .padding(.horizontal, 20)
            }
            Text(viewModel.isCorrectAnswer ? "" : incorrectMessage)

            Button {
                viewModel.confirmAnswer()
            } label: {
                Text("Confirm answer")
            }
            .disabled(viewModel.answerTextField.isEmpty)

            Spacer().frame(height: 100)

        }
        .navigationTitle("Spelling")
    }
}
