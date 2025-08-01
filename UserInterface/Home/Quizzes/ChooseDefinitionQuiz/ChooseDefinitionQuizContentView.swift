import SwiftUI

struct ChooseDefinitionQuizContentView: View {

    typealias ViewModel = ChooseDefinitionQuizViewModel

    @ObservedObject var viewModel: ViewModel

    init(viewModel: ChooseDefinitionQuizViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
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
            .onAppear {
                AnalyticsService.shared.logEvent(.definitionQuizOpened)
            }
        }
    }
}
