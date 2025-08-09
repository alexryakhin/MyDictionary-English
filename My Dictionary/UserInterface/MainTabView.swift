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
            .navigationDestination(for: CDWord.self) { word in
                WordDetailsContentView(word: word)
            }
            .navigationDestination(for: CDIdiom.self) { idiom in
                IdiomDetailsContentView(idiom: idiom)
            }
            .navigationDestination(for: DictionaryService.SharedDictionary.self) { dictionary in
                SharedDictionaryWordsView(dictionary: dictionary)
            }
            .navigationDestination(for: String.self) { destination in
                destinationView(for: destination)
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
    private func destinationView(for destination: String) -> some View {
        switch destination {
        case "add_word":
            AddWordContentView()
        case "add_shared_dictionary":
            AddSharedDictionaryView()
        case "add_idiom":
            AddIdiomContentView()
        case "quiz_results_detail":
            QuizResultsDetailView()
        case "about_app":
            AboutAppContentView()
        case "tag_management":
            TagManagementView()
        case "shared_dictionaries":
            SharedDictionariesListView()
        case "authentication":
            AuthenticationView()
        case let destination where destination.hasPrefix("spelling_quiz_"):
            let components = destination.components(separatedBy: "_")
            if components.count >= 4,
               let wordCount = Int(components[2]),
               let hardWordsOnly = Bool(components[3]) {
                SpellingQuizContentView(wordCount: wordCount, hardWordsOnly: hardWordsOnly)
            } else {
                EmptyView()
            }
        case let destination where destination.hasPrefix("choose_definition_quiz_"):
            let components = destination.components(separatedBy: "_")
            if components.count >= 5,
               let wordCount = Int(components[3]),
               let hardWordsOnly = Bool(components[4]) {
                ChooseDefinitionQuizContentView(wordCount: wordCount, hardWordsOnly: hardWordsOnly)
            } else {
                EmptyView()
            }
        case let destination where destination.hasPrefix("add_existing_word_"):
            // Handle add existing word to shared dictionary
            EmptyView() // Placeholder for now
        default:
            EmptyView()
        }
    }
}
