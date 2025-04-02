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
        let selection = Binding {
            viewModel.selectedQuiz
        } set: { quiz in
            if let quiz {
                viewModel.handle(.selectQuiz(quiz))
            }
        }

        List(selection: selection) {
            ForEach(Quiz.allCases) { quiz in
                QuizzesListCellView(quiz: quiz)
                    .tag(quiz)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .scrollIndicators(.hidden)
        .navigationTitle("Quizzes")
        .onDisappear {
            viewModel.handle(.deselectQuiz)
        }
        .background(Color.textBackgroundColor)
    }
}

#Preview {
    QuizzesView(viewModel: StateObject(wrappedValue: QuizzesViewModel()))
}
