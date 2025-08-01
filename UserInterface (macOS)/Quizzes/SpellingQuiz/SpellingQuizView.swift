import SwiftUI

struct SpellingQuizView: View {

    typealias ViewModel = SpellingQuizViewModel

    var _viewModel = StateObject(wrappedValue: SpellingQuizViewModel())
    var viewModel: ViewModel {
        _viewModel.wrappedValue
    }

    private var incorrectMessage: String {
        guard let randomWord = viewModel.randomWord else { return "" }

        if viewModel.attemptCount > 2 {
            return "Your word is '\(randomWord.word.trimmed)'. Try harder :)"
        } else {
            return "Incorrect. Try again"
        }
    }

    var body: some View {
        VStack(spacing: 12) {
            Spacer().frame(height: 100)

            Text(viewModel.randomWord?.definition ?? "Error")
                .font(.title)
                .bold()
                .padding(.horizontal, 30)
                .multilineTextAlignment(.center)

            Text(viewModel.randomWord?.partOfSpeech.rawValue ?? "error")
                .foregroundColor(.secondary)

            Spacer()

            VStack(spacing: 8) {
                Text("Guess the word and then spell it correctly in a text field below")
                    .foregroundColor(.secondary).font(.caption)

                HStack {
                    TextField("Answer", text: _viewModel.projectedValue.answerTextField, axis: .vertical)
                        .onSubmit {
                            viewModel.confirmAnswer()
                            AnalyticsService.shared.logEvent(.spellingQuizAnswerConfirmed)
                        }
                        .textFieldStyle(.plain)
                        .frame(maxWidth: 300)
                        .multilineTextAlignment(.center)
                }
                .clippedWithPaddingAndBackground(.surfaceColor)
                .padding(.horizontal, 20)
            }
            
            if !viewModel.isCorrectAnswer {
                Text(incorrectMessage)
                    .foregroundStyle(.secondary)
            }

            Button {
                viewModel.confirmAnswer()
                AnalyticsService.shared.logEvent(.spellingQuizAnswerConfirmed)
            } label: {
                Text("Confirm answer")
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.answerTextField.isEmpty)

            Spacer().frame(height: 100)

        }
        .navigationTitle("Spelling")
        .onAppear {
            AnalyticsService.shared.logEvent(.spellingQuizOpened)
        }
    }
}
