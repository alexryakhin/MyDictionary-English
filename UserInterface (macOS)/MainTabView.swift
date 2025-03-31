import SwiftUI
import CoreUserInterface__macOS_

public struct MainTabView: View {

    @State private var selectedSidebarItem: SidebarItem = .words
    @StateObject private var wordsViewModel = WordsViewModel()
    @StateObject private var idiomsViewModel = IdiomsViewModel()
    @StateObject private var quizzesViewModel = QuizzesViewModel()

    public init() { }

    public var body: some View {
        NavigationSplitView {
            tabsView
        } content: {
            tabContentView
        } detail: {
            tabDetailView
        }
        .fontDesign(.rounded)
        .background(Color.backgroundColor)
    }

    private var tabsView: some View {
        List(selection: $selectedSidebarItem) {
            Section {
                ForEach(SidebarItem.allCases, id: \.self) { item in
                    Label(item.title, systemImage: item.imageSystemName)
                        .tag(item)
                        .padding(.vertical, 8)
                        .font(.title3)
                }
            } header: {
                Text("My Dictionary")
                    .font(.title2)
                    .bold()
                    .padding(.vertical, 16)
            }
        }
    }

    @ViewBuilder
    private var tabContentView: some View {
        switch selectedSidebarItem {
        case .words:
            WordsListView(viewModel: _wordsViewModel)
        case .idioms:
            IdiomsListView(viewModel: _idiomsViewModel)
        case .quizzes:
            QuizzesView(viewModel: _quizzesViewModel)
        @unknown default:
            fatalError("Unsupported sidebar item: \(selectedSidebarItem)")
        }
    }

    @ViewBuilder
    private var tabDetailView: some View {
        switch selectedSidebarItem {
        case .words:
            if wordsViewModel.selectedWord == nil {
                Text("Select an item")
            } else {
                WordDetailsView(viewModel: _wordsViewModel)
            }
        case .idioms:
            if idiomsViewModel.selectedIdiom == nil {
                Text("Select an item")
            } else {
                IdiomDetailsView(viewModel: _idiomsViewModel)
            }
        case .quizzes:
            selectedQuizView
        @unknown default:
            fatalError("Unsupported sidebar item: \(selectedSidebarItem)")
        }
    }

    @ViewBuilder
    private var selectedQuizView: some View {
        switch quizzesViewModel.selectedQuiz {
        case .spelling:
            SpellingQuizView()
        case .chooseDefinitions:
            ChooseDefinitionView()
        default:
            Text("Select an item")
        }
    }
}
