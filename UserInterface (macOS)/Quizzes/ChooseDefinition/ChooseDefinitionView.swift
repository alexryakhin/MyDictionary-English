import SwiftUI
import Core
import CoreUserInterface__macOS_
import Shared

struct ChooseDefinitionView: PageView {

    typealias ViewModel = ChooseDefinitionViewModel

    var _viewModel: StateObject<ViewModel>
    var viewModel: ViewModel {
        _viewModel.wrappedValue
    }

    init(viewModel: StateObject<ViewModel>) {
        self._viewModel = viewModel
    }

    var contentView: some View {
        if !viewModel.words.isEmpty {
            VStack {
                Spacer().frame(height: 100)

                Text(viewModel.words[viewModel.correctAnswerIndex].word)
                    .font(.largeTitle)
                    .bold()
                Text(viewModel.words[viewModel.correctAnswerIndex].partOfSpeech.rawValue)
                    .foregroundColor(.secondary)

                Spacer()
                Text("Choose from the given definitions below")
                    .font(.caption)
                    .foregroundColor(.secondary)

                ForEach(0..<3) { index in
                    Text(viewModel.words[index].definition)
                        .foregroundColor(.primary)
                        .frame(width: 300)
                        .padding(16)
                        .background(Color.secondary.opacity(0.3))
                        .cornerRadius(15)
                        .padding(3)
                        .onTapGesture {
                            viewModel.answerSelected(index)
                        }
                }

                Text(viewModel.isCorrectAnswer ? "" : "Incorrect. Try Again")
                Spacer().frame(height: 100)
            }
            .ignoresSafeArea()
            .navigationTitle("Choose Definition")
            .onAppear {
                viewModel.correctAnswerIndex = Int.random(in: 0...2)
            }
        }
    }
}
