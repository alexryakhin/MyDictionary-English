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
    @StateObject var onboardingService: OnboardingService = .shared
    @StateObject var keyboardManager: KeyboardManager = .shared

    var body: some View {
#if DEBUG
let _ = Self._printChanges()
#endif
        NavigationStack(path: $navigationManager.navigationPath) {
            if #available(iOS 26.0, *) {
                TabView(selection: $tabManager.selectedTab) {
                    VocabularyFlow(
                        wordListViewModel: wordListViewModel,
                        idiomListViewModel: idiomListViewModel
                    )
                    .tabItem {
                        Label(
                            TabBarItem.myDictionary.title,
                            systemImage: TabBarItem.myDictionary.image
                        )
                    }
                    .tag(TabBarItem.myDictionary)

                    QuizzesFlow(viewModel: quizzesViewModel)
                        .tabItem {
                            Label(
                                TabBarItem.quizzes.title,
                                systemImage: TabBarItem.quizzes.image
                            )
                        }
                        .tag(TabBarItem.quizzes)

                    DiscoverFlow()
                        .tabItem {
                            Label(
                                TabBarItem.discover.title,
                                systemImage: TabBarItem.discover.image
                            )
                        }
                        .tag(TabBarItem.discover)

                    AnalyticsFlow(viewModel: analyticsViewModel)
                        .tabItem {
                            Label(
                                TabBarItem.analytics.title,
                                systemImage: TabBarItem.analytics.image
                            )
                        }
                        .tag(TabBarItem.analytics)

                    SettingsFlow(viewModel: settingsViewModel)
                        .tabItem {
                            Label(
                                TabBarItem.settings.title,
                                systemImage: TabBarItem.settings.image
                            )
                        }
                        .tag(TabBarItem.settings)
                }
                .environment(\.horizontalSizeClass, .compact)
                .navigationDestination(for: NavigationDestination.self) { destination in
                    destinationView(for: destination)
                }
            } else {
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
                        case .quizzes:
                            QuizzesFlow(viewModel: quizzesViewModel)
                        case .discover:
                            DiscoverFlow()
                        case .analytics:
                            AnalyticsFlow(viewModel: analyticsViewModel)
                        case .settings:
                            SettingsFlow(viewModel: settingsViewModel)
                        }
                    }
                }
                .safeAreaBarIfAvailable {
                    tabBarView
                }
                .navigationDestination(for: NavigationDestination.self) { destination in
                    destinationView(for: destination)
                }
            }
        }
        .withPaywall()
        .fullScreenCover(isPresented: $onboardingService.showOnboarding) {
            OnboardingFlow.ContainerView(isNewUser: false)
        }
        .task {
            // Check for existing profile in iCloud on first launch
            await onboardingService.checkForExistingProfileInCloud()
            
            // Clean up any existing duplicates (production-safe)
            await onboardingService.cleanupDuplicatesIfNeeded()
        }
    }

    @ViewBuilder
    private var tabBarView: some View {
        GlassTabBar(
            activeTab: Binding {
                tabManager.selectedTab
            } set: { newTab in
                tabManager.switchToTab(newTab)
                HapticManager.shared.triggerImpact(style: .soft)
            }
        )
        .hidden(keyboardManager.isKeyboardPresented)
    }
    
    @ViewBuilder
    private func destinationView(for destination: NavigationDestination) -> some View {
        switch destination {
        case .addWord(let config):
            AddWordView(config: config)
        case .quizResultsList:
            QuizResultsList.ContentView()
        case .allQuizActivity:
            AllQuizActivityView()
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
        case .deleteWords:
            DeleteWordsView()
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
        case .pronunciationPracticeQuiz(let preset):
            PronunciationPracticeQuizContentView(preset: preset)
        case .storyLabHistory:
            StoryLabHistoryView()
        case .storyLabReading(let config):
            StoryLabReadingView(config: config)
        case .storyLabResults(let config):
            StoryLabResultsView(config: config)
        case .musicPlayer(let config):
            SongPlayerView(config: config)
        case .songLesson(let config):
            SongLessonView(config: config)
        case .songLessonResults(let config):
            SongLessonResultsView(session: config.session, song: config.song)
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
        case .wordCollections:
            WordCollectionsView()
        case .wordCollectionDetails(let collection):
            WordCollectionDetailsView(collection: collection)
        }
    }
}
