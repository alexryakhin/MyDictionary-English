import SwiftUI
import RevenueCatUI

struct MainTabView: View {

    // MARK: - Tab view models

    @StateObject private var wordsViewModel = WordListViewModel()
    @StateObject private var idiomsViewModel = IdiomListViewModel()
    @StateObject private var quizzesViewModel = QuizzesListViewModel()
    @StateObject private var analyticsViewModel = AnalyticsViewModel()
    @StateObject private var settingsViewModel = SettingsViewModel()

    // MARK: - Properties

    @AppStorage(UDKeys.isShowingOnboarding) var isShowingOnboarding: Bool = true
    @AppStorage(UDKeys.showIdiomsTab) var showIdiomsTab: Bool = true
    @StateObject var navigationManager: NavigationManager = .shared
    @StateObject var tabManager: TabManager = .shared
    @StateObject var authenticationService: AuthenticationService = .shared
    @StateObject var subscriptionService: SubscriptionService = .shared
    @StateObject var sessionManager: SessionManager = .shared

    var body: some View {
        NavigationStack(path: $navigationManager.navigationPath) {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                HStack {
                    switch tabManager.selectedTab {
                    case .words:
                        WordsFlow(viewModel: wordsViewModel)
                            .transition(tabManager.getSlideTransition())
                    case .idioms:
                        IdiomsFlow(viewModel: idiomsViewModel)
                            .transition(tabManager.getSlideTransition())
                    case .quizzes:
                        QuizzesFlow(viewModel: quizzesViewModel)
                            .transition(tabManager.getSlideTransition())
                    case .analytics:
                        AnalyticsFlow(viewModel: analyticsViewModel)
                            .transition(tabManager.getSlideTransition())
                    case .settings:
                        SettingsFlow(viewModel: settingsViewModel)
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
                    .interactiveDismissDisabled()
            }
            .navigationDestination(for: NavigationDestination.self) { destination in
                destinationView(for: destination)
            }
            .overlay {
                SignOutView()
            }
            .withPaywall()
            .sheet(isPresented: $sessionManager.showCoffeeBanner) {
                CoffeeBanner(
                    onBuyCoffee: {
                        UIApplication.shared.open(GlobalConstant.buyMeACoffeeUrl)
                        sessionManager.markCoffeeBannerShown()
                        AnalyticsService.shared.logEvent(.coffeeBannerTapped)
                    },
                    onDismiss: {
                        sessionManager.markCoffeeBannerDismissed()
                        AnalyticsService.shared.logEvent(.coffeeBannerDismissed)
                    }
                )
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
            }
        }
    }

    @ViewBuilder
    private var tabBarView: some View {
        let tabCases = TabBarItem.allCases
            .filter { tab in
                if tab == .idioms {
                    showIdiomsTab
                } else {
                    true
                }
            }
        HStack {
            ForEach(tabCases, id: \.self) { tab in
                TabButton(
                    title: tab.title,
                    image: tab.image,
                    imageSelected: tab.selectedImage,
                    isSelected: tabManager.selectedTab == tab
                ) {
                    tabManager.switchToTab(tab)
                    HapticManager.shared.triggerImpact(style: .soft)
                }
            }
        }
        .padding(vertical: 12, horizontal: 16)
        .clippedWithBackgroundMaterial(.ultraThinMaterial, cornerRadius: 32)
        .shadow(radius: 2)
        .padding(8)
    }
    
    @ViewBuilder
    private func destinationView(for destination: NavigationDestination) -> some View {
        switch destination {
        case .addWord:
            AddWordContentView()
        case .addSharedDictionary:
            if subscriptionService.isProUser {
                AddSharedDictionaryView()
                    .presentationCornerRadius(24)
            } else {
                MyPaywallView()
            }
        case .addIdiom:
            AddIdiomContentView()
        case .quizResultsDetail:
            QuizResultsDetailView()
        case .aboutApp:
            AboutAppContentView()
        case .tagManagement:
            TagManagementView()
        case .sharedDictionariesList:
            SharedDictionariesListView()
        case .authentication:
            AuthenticationView()
        case .spellingQuiz(let wordCount, let hardWordsOnly):
            SpellingQuizContentView(wordCount: wordCount, hardWordsOnly: hardWordsOnly)
        case .chooseDefinitionQuiz(let wordCount, let hardWordsOnly):
            ChooseDefinitionQuizContentView(wordCount: wordCount, hardWordsOnly: hardWordsOnly)
        case .wordDetails(let word):
            WordDetailsContentView(word: word)
        case .addExistingWordToShared(let word):
            AddExistingWordToSharedView(word: word)
        case .idiomDetails(let idiom):
            IdiomDetailsContentView(idiom: idiom)
        case .sharedDictionaryWords(let dictionary):
            SharedDictionaryWordsView(dictionary: dictionary)
        case .sharedDictionaryDetails(let dictionary):
            SharedDictionaryDetailsView(dictionary: dictionary)
        case .sharedWordDetails(let word, let dictionaryId):
            SharedWordDetailsView(word: word, dictionaryId: dictionaryId)
        case .sharedWordDifficultyStats(let word, let dictionaryId):
            SharedWordDifficultyStatsView(word: word, dictionaryId: dictionaryId)
        }
    }
}
