import SwiftUI

struct SideBarView: View {

    @Environment(\.openWindow) private var openWindow
    @Environment(\.openSettings) private var openSettings
    @AppStorage(UDKeys.hasCompletedOnboarding) var hasCompletedOnboarding: Bool = false

    @StateObject private var sideBarManager = SideBarManager.shared
    @StateObject private var dictionaryService = DictionaryService.shared
    @StateObject private var authenticationService = AuthenticationService.shared
    @StateObject private var sessionManager = SessionManager.shared

    var body: some View {
        NavigationSplitView {
            sidebarView
                .frame(width: 200)
                .toolbar(removing: .sidebarToggle)

        } detail: {
            HStack(spacing: 0) {
                contentListView
                if sideBarManager.selectedTab != .analytics {
                    Divider()
                }
                detailView
            }
        }
        .groupedBackground()
        .navigationSplitViewStyle(.automatic)
        .withPaywall()
        .sheet(isPresented: $sessionManager.showCoffeeBanner) {
            CoffeeBanner()
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: .constant(hasCompletedOnboarding == false)) {
            hasCompletedOnboarding = true
        } content: {
            OnboardingView()
                .interactiveDismissDisabled()
        }
    }

    // MARK: - Sidebar View (Column 1)
    
    private var sidebarView: some View {
        List(selection: $sideBarManager.selectedTab) {
            Section(Loc.SharedDictionaries.privateDictionary) {
                ForEach(SideBarTab.tabs, id: \.self) { tab in
                    HStack(spacing: 8) {
                        Image(systemName: tab.systemImage)
                        Text(tab.title)
                    }
                    .tag(tab)
                    .font(.title3)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 8)
                }
            }

            if authenticationService.isSignedIn {
                Section(Loc.SharedDictionaries.sharedDictionaries) {
                    if dictionaryService.sharedDictionaries.isEmpty {
                        Text(Loc.SharedDictionaries.noSharedDictionariesSidebar)
                            .foregroundStyle(.secondary)
                            .font(.caption)
                            .padding(.vertical, 4)
                    } else {
                        ForEach(dictionaryService.sharedDictionaries, id: \.id) { dictionary in
                            HStack(spacing: 8) {
                                Image(systemName: "person.3")
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(dictionary.name)
                                        .font(.title3)
                                    Text(Loc.SharedDictionaries.collaboratorsCount(dictionary.collaborators.count))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 8)
                            .tag(SideBarTab.sharedDictionary(dictionary))
                        }
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .listStyle(.sidebar)
        .safeAreaInset(edge: .bottom) {
            VStack {
                Button {
                    openSettings()
                } label: {
                    Label(Loc.Navigation.Tabbar.settings, systemImage: "gearshape.fill")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(vertical: 10, horizontal: 8)
                        .font(.title3)
                        .clippedWithBackgroundMaterial(cornerRadius: 12)
                }
                .buttonStyle(.plain)

                Button {
                    openWindow(id: WindowID.about)
                } label: {
                    Label(Loc.Settings.aboutApp, systemImage: "info.circle")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(vertical: 10, horizontal: 8)
                        .font(.title3)
                        .clippedWithBackgroundMaterial(cornerRadius: 12)
                }
                .buttonStyle(.plain)
            }
            .padding(12)
        }
    }

    // MARK: - Content List View (Column 2)

    @ViewBuilder
    private var contentListView: some View {
        switch sideBarManager.selectedTab {
        case .myDictionary:
            VocabularyListView()
                .frame(width: 300, alignment: .leading)
                .frame(maxWidth: .infinity, alignment: .leading)
        case .quizzes:
            QuizzesListView()
                .frame(width: 300, alignment: .leading)
        case .analytics:
            AnalyticsView()
                .frame(width: 450, alignment: .leading)
        case .sharedDictionary(let dictionary):
            SharedDictionaryWordsView(dictionary: dictionary)
                .id(dictionary.id)
                .frame(width: 300, alignment: .leading)
                .frame(maxWidth: .infinity, alignment: .leading)
        case .none:
            EmptyView()
        }
    }

    // MARK: - Detail View (Column 3)

    @ViewBuilder
    private var detailView: some View {
        switch sideBarManager.selectedDetailItem {
        case .word(let cdWord):
            WordDetailsView(word: cdWord)
                .id(sideBarManager.selectedWord?.id)
                .frame(maxWidth: .infinity, alignment: .leading)
                .layoutPriority(1)
        case .sharedWord(let sharedWord, let dictionaryId):
            SharedWordDetailsView(word: sharedWord, dictionaryId: dictionaryId)
                .id(sideBarManager.selectedSharedWord?.id)
                .frame(maxWidth: .infinity, alignment: .leading)
                .layoutPriority(1)
        case .idiom(let cdWord):
            WordDetailsView(word: cdWord)
                .id(sideBarManager.selectedIdiom?.id)
                .frame(maxWidth: .infinity, alignment: .leading)
                .layoutPriority(1)
        case .quiz(let quiz):
            switch quiz {
            case .chooseDefinition(let preset):
                ChooseDefinitionQuizView(preset: preset)
                    .id(sideBarManager.selectedQuiz)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .layoutPriority(1)
            case .spelling(let preset):
                SpellingQuizView(preset: preset)
                    .id(sideBarManager.selectedQuiz)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .layoutPriority(1)
            }
        case nil:
            if let text = sideBarManager.selectedTab?.selectDetailsText {
                Text(text)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .layoutPriority(1)
            }
        }
    }
}
