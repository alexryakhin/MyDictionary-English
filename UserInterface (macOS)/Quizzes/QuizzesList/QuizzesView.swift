import SwiftUI
import Core
import CoreUserInterface__macOS_
import Shared

struct QuizzesView: PageView {

    typealias ViewModel = QuizzesViewModel

    var _viewModel: StateObject<ViewModel>
    var viewModel: ViewModel {
        _viewModel.wrappedValue
    }

    init(viewModel: StateObject<ViewModel>) {
        self._viewModel = viewModel
    }

    var contentView: some View {
        VStack(alignment: .leading) {
            if viewModel.words.count < 10 {
                if #available(macOS 14.0, *) {
                    ContentUnavailableView {
                        Text("Add at least 10 words to your list to play!")
                    }
                } else {
                    Spacer()
                    Text("Add at least 10 words\nto your list to play!")
                        .lineSpacing(10)
                        .font(.title3)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                    Spacer()
                }
            } else {
                ScrollView(showsIndicators: false) {
                    ListWithDivider(Quiz.allCases) { quiz in
                        QuizzesListCellView(
                            model: .init(
                                text: quiz.title,
                                isSelected: viewModel.selectedQuiz == quiz
                            ) {
                                viewModel.selectedQuiz = quiz
                            }
                        )
                    }
                }
            }
        }
        .navigationTitle("Quizzes")
        .onDisappear {
            viewModel.selectedQuiz = nil
        }
    }
}

#Preview {
    QuizzesView(viewModel: StateObject(wrappedValue: QuizzesViewModel()))
}
