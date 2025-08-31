import SwiftUI
import RevenueCatUI

struct MainTabView: View {

    // MARK: - Tab view models

    @StateObject private var wordListViewModel = WordListViewModel()
    @StateObject private var idiomListViewModel = IdiomListViewModel()
    @StateObject private var quizzesViewModel = QuizzesListViewModel()
    @StateObject private var analyticsViewModel = AnalyticsViewModel()
    @StateObject private var settingsViewModel = SettingsViewModel()

    // MARK: - Properties

    @AppStorage(UDKeys.hasCompletedOnboarding) var hasCompletedOnboarding: Bool = false
    @StateObject var navigationManager: NavigationManager = .shared
    @StateObject var tabManager: TabManager = .shared
    @StateObject var authenticationService: AuthenticationService = .shared
    @StateObject var subscriptionService: SubscriptionService = .shared
    @StateObject var sessionManager: SessionManager = .shared

    var body: some View {
        NavigationStack(path: $navigationManager.navigationPath) {
            ZStack {
                Color.systemGroupedBackground
                    .ignoresSafeArea()
                HStack {
                    switch tabManager.selectedTab {
                    case .myDictionary:
                        VocabularyFlow(
                            wordListViewModel: wordListViewModel,
                            idiomListViewModel: idiomListViewModel
                        )
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
            .sheet(isPresented: .constant(hasCompletedOnboarding == false)) {
                hasCompletedOnboarding = true
            } content: {
                OnboardingView()
                    .interactiveDismissDisabled()
            }
            .navigationDestination(for: NavigationDestination.self) { destination in
                destinationView(for: destination)
            }
            .withPaywall()
            .sheet(isPresented: $sessionManager.showCoffeeBanner) {
                CoffeeBanner()
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
            }
        }
    }

    @ViewBuilder
    private var tabBarView: some View {
        let tabCases = TabBarItem.allCases
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
        case .addWord(let input, let isWord):
            AddWordView(input: input, isWord: isWord)
        case .quizResultsList:
            QuizResultsList.ContentView()
        case .aboutApp:
            AboutAppContentView()
        case .tagManagement:
            TagManagementView()
        case .sharedDictionariesList:
            SharedDictionariesListView()
        case .authentication:
            AuthenticationView(feature: .syncWords)
        case .profile:
            ProfileView()
        case .ttsDashboard:
            TTSDashboard.ContentView()
        case .spellingQuiz(let preset):
            SpellingQuizContentView(preset: preset)
        case .chooseDefinitionQuiz(let preset):
            ChooseDefinitionQuizContentView(preset: preset)
        case .sentenceWritingQuiz(let preset):
            SentenceWritingQuizContentView(preset: preset)
        case .contextMultipleChoiceQuiz(let preset):
            ContextMultipleChoiceQuizContentView(preset: preset)
        case .fillInTheBlankQuiz(let preset):
            FillInTheBlankQuizContentView(preset: preset)
        case .wordDetails(let word):
            WordDetailsContentView(word: word)
        case .wordMeaningsList(let word):
            MeaningsListView(word: word)
        case .addExistingWordToShared(let word):
            AddExistingWordToSharedView(word: word)
        case .sharedDictionaryWords(let dictionary):
            SharedDictionaryWordsView(dictionary: dictionary)
        case .sharedDictionaryDetails(let dictionary):
            SharedDictionaryDetailsView(dictionary: dictionary)
        case .sharedWordDetails(let word, let dictionaryId):
            SharedWordDetailsView(word: word, dictionaryId: dictionaryId)
        case .sharedWordDifficultyStats(let word):
            SharedWordDifficultyStatsView(word: word)
        }
    }
}
