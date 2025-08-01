import SwiftUI

struct MainTabView: View {

    @ObservedObject var wordsViewModel: WordsListViewModel
    @ObservedObject var idiomsViewModel: IdiomsListViewModel
    @ObservedObject var quizzesViewModel: QuizzesListViewModel
    @ObservedObject var moreViewModel: MoreViewModel

    @StateObject var navigationManager: NavigationManager = .shared

    init(
        wordsViewModel: WordsListViewModel,
        idiomsViewModel: IdiomsListViewModel,
        quizzesViewModel: QuizzesListViewModel,
        moreViewModel: MoreViewModel
    ) {
        self._wordsViewModel = ObservedObject(wrappedValue: wordsViewModel)
        self._idiomsViewModel = ObservedObject(wrappedValue: idiomsViewModel)
        self._quizzesViewModel = ObservedObject(wrappedValue: quizzesViewModel)
        self._moreViewModel = ObservedObject(wrappedValue: moreViewModel)
    }

    var body: some View {
        TabView(selection: $navigationManager.selectedTab) {
            NavigationSplitView(columnVisibility: .constant(.all)) {
                WordsListContentView(viewModel: wordsViewModel)
            } detail: {
                if let selectedWord = wordsViewModel.selectedWord {
                    WordDetailsContentView(word: selectedWord)
                        .id(wordsViewModel.selectedWord?.id)
                } else {
                    ContentUnavailableView(
                        "No Word Selected",
                        systemImage: "textformat",
                        description: Text("Select a word from the list to view its details")
                    )
                }
            }
            .navigationSplitViewStyle(.balanced)
            .tabItem {
                Label(
                    TabBarItem.words.title,
                    systemImage: TabBarItem.words.image
                )
            }
            .tag(TabBarItem.words)

            NavigationSplitView(columnVisibility: .constant(.all)) {
                IdiomsListContentView(viewModel: idiomsViewModel)
            } detail: {
                if let selectedIdiom = idiomsViewModel.selectedIdiom {
                    IdiomDetailsContentView(idiom: selectedIdiom)
                        .id(idiomsViewModel.selectedIdiom?.id)
                } else {
                    ContentUnavailableView(
                        "No Idiom Selected",
                        systemImage: "quote.bubble",
                        description: Text("Select an idiom from the list to view its details")
                    )
                }
            }
            .navigationSplitViewStyle(.balanced)
            .tabItem {
                Label(
                    TabBarItem.idioms.title,
                    systemImage: TabBarItem.idioms.image
                )
            }
            .tag(TabBarItem.idioms)

            NavigationView {
                QuizzesListContentView(viewModel: quizzesViewModel)
            }
            .navigationSplitViewStyle(.balanced)
            .tabItem {
                Label(
                    TabBarItem.quizzes.title,
                    systemImage: TabBarItem.quizzes.image
                )
            }
            .tag(TabBarItem.quizzes)

            NavigationView {
                MoreContentView(viewModel: moreViewModel)
            }
            .tabItem {
                Label(
                    TabBarItem.more.title,
                    systemImage: TabBarItem.more.image
                )
            }
            .tag(TabBarItem.more)
        }
    }

    // MARK: - iPad Navigation
    
    @ViewBuilder
    private var sidebarView: some View {
        List {
            Section("My Dictionary") {
                NavigationLink("Words", value: NavigationItem.words)
                NavigationLink("Idioms", value: NavigationItem.idioms)
                NavigationLink("Quizzes", value: NavigationItem.quizzes)
                NavigationLink("More", value: NavigationItem.more)
            }
        }
        .navigationTitle("My Dictionary")
    }
    
    @ViewBuilder
    private var contentView: some View {
        // Content area for iPad - could be empty or show a placeholder
        Text("Select an item from the sidebar")
            .foregroundColor(.secondary)
    }
    
    @ViewBuilder
    private var detailView: some View {
        // Detail area for iPad - could be empty or show a placeholder
        Text("Select an item from the sidebar")
            .foregroundColor(.secondary)
    }
}

// MARK: - Navigation Items

enum NavigationItem: Hashable {
    case words
    case idioms
    case quizzes
    case more
} 
