import SwiftUI

struct MainTabView: View {

    // MARK: - Tab view models

    @StateObject private var wordsViewModel = WordListViewModel()
    @StateObject private var idiomsViewModel = IdiomListViewModel()
    @StateObject private var quizzesViewModel = QuizzesListViewModel()
    @StateObject private var analyticsViewModel = AnalyticsViewModel()
    @StateObject private var settingsViewModel = SettingsViewModel()

    // MARK: - Properties

    @State private var navigationPath = NavigationPath()
    @AppStorage(UDKeys.isShowingOnboarding) var isShowingOnboarding: Bool = true
    @StateObject var tabManager: TabManager = .shared
    @StateObject var authenticationService: AuthenticationService = .shared

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                HStack {
                    switch tabManager.selectedTab {
                    case .words:
                        WordsFlow(navigationPath: $navigationPath, viewModel: wordsViewModel)
                            .transition(tabManager.getSlideTransition())
                    case .idioms:
                        IdiomsFlow(navigationPath: $navigationPath, viewModel: idiomsViewModel)
                            .transition(tabManager.getSlideTransition())
                    case .quizzes:
                        QuizzesFlow(navigationPath: $navigationPath, viewModel: quizzesViewModel)
                            .transition(tabManager.getSlideTransition())
                    case .analytics:
                        AnalyticsFlow(navigationPath: $navigationPath, viewModel: analyticsViewModel)
                            .transition(tabManager.getSlideTransition())
                    case .settings:
                        SettingsFlow(navigationPath: $navigationPath, viewModel: settingsViewModel)
                            .transition(tabManager.getSlideTransition())
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                tabBarView
            }
            .sheet(isPresented: $isShowingOnboarding) {
                isShowingOnboarding = false
            } content: {
                OnboardingView()
            }
            .navigationDestination(for: NavigationDestination.self) { destination in
                destinationView(for: destination)
            }
            .overlay {
                SignOutView()
            }
            .onReceive(tabManager.popToRootPublisher) {
                navigationPath.removeLast(navigationPath.count)
            }
        }
    }

    private var tabBarView: some View {
        HStack {
            ForEach(TabBarItem.allCases, id: \.self) { tab in
                TabButton(
                    title: tab.title,
                    image: tab.image,
                    imageSelected: tab.selectedImage,
                    isSelected: tabManager.selectedTab == tab
                ) {
                    tabManager.switchToTab(tab)
                }
            }
        }
        .padding(vertical: 12, horizontal: 16)
        .clippedWithBackgroundMaterial(.ultraThinMaterial)
        .shadow(radius: 2)
        .padding(8)
    }
    
    @ViewBuilder
    private func destinationView(for destination: NavigationDestination) -> some View {
        switch destination {
        case .addWord:
            AddWordContentView()
        case .addSharedDictionary:
            AddSharedDictionaryView()
        case .addIdiom:
            AddIdiomContentView()
        case .quizResultsDetail:
            QuizResultsDetailView()
        case .aboutApp:
            AboutAppContentView()
        case .tagManagement:
            TagManagementView()
        case .sharedDictionariesList:
            SharedDictionariesListView(navigationPath: $navigationPath)
        case .authentication:
            AuthenticationView()
        case .spellingQuiz(let wordCount, let hardWordsOnly):
            SpellingQuizContentView(wordCount: wordCount, hardWordsOnly: hardWordsOnly)
        case .chooseDefinitionQuiz(let wordCount, let hardWordsOnly):
            ChooseDefinitionQuizContentView(wordCount: wordCount, hardWordsOnly: hardWordsOnly)
        case .wordDetails(let config):
            WordDetailsContentView(config: config)
        case .addExistingWordToShared(let config):
            AddExistingWordToSharedView(config: config)
        case .idiomDetails(let idiom):
            IdiomDetailsContentView(idiom: idiom)
        case .sharedDictionaryWords(let dictionary):
            SharedDictionaryWordsView(navigationPath: $navigationPath, dictionary: dictionary)
        case .sharedDictionaryDetails(let dictionary):
            SharedDictionaryDetailsView(dictionary: dictionary)
        }
    }
}
