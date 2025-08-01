import SwiftUI

struct MainTabView: View {

    @StateObject var wordsViewModel: WordsListViewModel
    @StateObject var idiomsViewModel: IdiomsListViewModel
    @StateObject var quizzesViewModel: QuizzesListViewModel
    @StateObject var moreViewModel: MoreViewModel
    @StateObject var navigationManager: NavigationManager = .shared

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
        Group {
            if isPad {
                // iPad: Use NavigationSplitView for better iPad experience
                NavigationSplitView {
                    sidebarView
                } content: {
                    contentView
                } detail: {
                    detailView
                }
            } else {
                // iPhone: Use TabView with NavigationView for each tab
                TabView(selection: $navigationManager.selectedTab) {
                    NavigationView {
                        WordsListContentView(viewModel: wordsViewModel)
                    }
                    .tabItem {
                        Label(
                            TabBarItem.words.title,
                            systemImage: TabBarItem.words.image
                        )
                    }
                    .tag(TabBarItem.words)

                    NavigationView {
                        IdiomsListContentView(viewModel: idiomsViewModel)
                    }
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
                .environment(\.horizontalSizeClass, .compact)
                .navigationViewStyle(.stack)
            }
        }
        .fontDesign(.rounded)
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
