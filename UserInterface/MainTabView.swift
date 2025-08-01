import SwiftUI

struct MainTabView: View {

    @ObservedObject var wordsViewModel: WordsListViewModel
    @ObservedObject var idiomsViewModel: IdiomsListViewModel
    @ObservedObject var quizzesViewModel: QuizzesListViewModel
    @ObservedObject var analyticsViewModel: AnalyticsViewModel
    @ObservedObject var moreViewModel: MoreViewModel

    @StateObject var navigationManager: NavigationManager = .shared

    init(
        wordsViewModel: WordsListViewModel,
        idiomsViewModel: IdiomsListViewModel,
        quizzesViewModel: QuizzesListViewModel,
        analyticsViewModel: AnalyticsViewModel,
        moreViewModel: MoreViewModel
    ) {
        self._wordsViewModel = ObservedObject(wrappedValue: wordsViewModel)
        self._idiomsViewModel = ObservedObject(wrappedValue: idiomsViewModel)
        self._quizzesViewModel = ObservedObject(wrappedValue: quizzesViewModel)
        self._analyticsViewModel = ObservedObject(wrappedValue: analyticsViewModel)
        self._moreViewModel = ObservedObject(wrappedValue: moreViewModel)
    }

    var body: some View {
        TabView(selection: $navigationManager.selectedTab) {
            // Words Tab
            NavigationSplitView {
                WordsListContentView(viewModel: wordsViewModel)
            } detail: {
                if let selectedWord = wordsViewModel.selectedWord {
                    WordDetailsContentView(word: selectedWord)
                        .id(selectedWord.id)
                } else {
                    Text("Select a word")
                        .foregroundColor(.secondary)
                }
            }
            .tabItem {
                Label(TabBarItem.words.title, systemImage: TabBarItem.words.image)
            }
            .tag(TabBarItem.words)

            // Idioms Tab
            NavigationSplitView {
                IdiomsListContentView(viewModel: idiomsViewModel)
            } detail: {
                if let selectedIdiom = idiomsViewModel.selectedIdiom {
                    IdiomDetailsContentView(idiom: selectedIdiom)
                        .id(selectedIdiom.id)
                } else {
                    Text("Select an idiom")
                        .foregroundColor(.secondary)
                }
            }
            .tabItem {
                Label(TabBarItem.idioms.title, systemImage: TabBarItem.idioms.image)
            }
            .tag(TabBarItem.idioms)

            // Quizzes Tab
            NavigationView {
                QuizzesListContentView(viewModel: quizzesViewModel)
            }
            .tabItem {
                Label(TabBarItem.quizzes.title, systemImage: TabBarItem.quizzes.image)
            }
            .tag(TabBarItem.quizzes)

            // Progress Tab
            NavigationView {
                AnalyticsContentView()
            }
            .tabItem {
                Label(TabBarItem.analytics.title, systemImage: TabBarItem.analytics.image)
            }
            .tag(TabBarItem.analytics)

            // Settings Tab
            NavigationView {
                MoreContentView(viewModel: moreViewModel)
            }
            .tabItem {
                Label(TabBarItem.settings.title, systemImage: TabBarItem.settings.image)
            }
            .tag(TabBarItem.settings)
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
