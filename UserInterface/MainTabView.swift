import SwiftUI

struct MainTabView: View {

    @StateObject var wordsViewModel: WordsListViewModel
    @StateObject var idiomsViewModel: IdiomsListViewModel
    @StateObject var quizzesViewModel: QuizzesListViewModel
    @StateObject var moreViewModel: MoreViewModel

    init(
        wordsViewModel: WordsListViewModel,
        idiomsViewModel: IdiomsListViewModel,
        quizzesViewModel: QuizzesListViewModel,
        moreViewModel: MoreViewModel
    ) {
        self._wordsViewModel = StateObject(wrappedValue: wordsViewModel)
        self._idiomsViewModel = StateObject(wrappedValue: idiomsViewModel)
        self._quizzesViewModel = StateObject(wrappedValue: quizzesViewModel)
        self._moreViewModel = StateObject(wrappedValue: moreViewModel)
    }

    var body: some View {
        TabView {
            WordsListContentView(viewModel: wordsViewModel)
                .tabItem {
                    Image(systemName: "textformat")
                    Text("Words")
                }

            IdiomsListContentView(viewModel: idiomsViewModel)
                .tabItem {
                    Image(systemName: "quote.bubble")
                    Text("Idioms")
                }

            QuizzesListContentView(viewModel: quizzesViewModel)
                .tabItem {
                    Image(systemName: "questionmark.circle")
                    Text("Quizzes")
                }

            MoreContentView(viewModel: moreViewModel)
                .tabItem {
                    Image(systemName: "ellipsis.circle")
                    Text("More")
                }
        }
        .fontDesign(.rounded)
    }
} 
