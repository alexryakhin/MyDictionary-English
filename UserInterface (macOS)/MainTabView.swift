import SwiftUI

struct MainTabView: View {

    @State private var selectedSidebarItem: SidebarItem = .words
    @StateObject private var wordsViewModel = WordsViewModel()
    @StateObject private var idiomsViewModel = IdiomsViewModel()
    @StateObject private var quizzesViewModel = QuizzesViewModel()

    init() { }

    var body: some View {
        NavigationSplitView {
            tabsView
                .frame(minWidth: 160)
        } content: {
            tabContentView
                .frame(minWidth: 250)
        } detail: {
            tabDetailView
                .frame(minWidth: 500)
        }
        .fontDesign(.rounded)
        .frame(minHeight: 500)
    }

    private var tabsView: some View {
        List(selection: $selectedSidebarItem) {
            Section {
                ForEach(SidebarItem.allCases, id: \.self) { item in
                    HStack(spacing: 8) {
                        Image(systemName: item.imageSystemName)
                        Text(item.title)
                    }
                    .tag(item)
                    .font(.title3)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 8)
                }
            } header: {
                Text("My Dictionary")
                    .font(.title2)
                    .bold()
                    .padding(.vertical, 16)
            }
        }
        .safeAreaInset(edge: .bottom) {
            SettingsButton {
                Label("Settings", systemImage: "gearshape.fill")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(vertical: 10, horizontal: 8)
                    .font(.title3)
            }
            .padding(vertical: 8, horizontal: 12)
        }
    }

    @ViewBuilder
    private var tabContentView: some View {
        switch selectedSidebarItem {
        case .words:
            WordsListView(viewModel: wordsViewModel)
        case .idioms:
            IdiomsListView(viewModel: idiomsViewModel)
        case .quizzes:
            QuizzesView(viewModel: _quizzesViewModel)
        case .progress:
            ProgressAnalyticsView()
        @unknown default:
            fatalError("Unsupported sidebar item: \(selectedSidebarItem)")
        }
    }

    @ViewBuilder
    private var tabDetailView: some View {
        switch selectedSidebarItem {
        case .words:
            if let selectedWord = wordsViewModel.selectedWord {
                WordDetailsView(word: selectedWord)
                    .id(selectedWord.id)
            } else {
                Text("Select a word")
                    .toolbar(content: toolbarPlaceholder)
            }
        case .idioms:
            if let selectedIdiom = idiomsViewModel.selectedIdiom {
                IdiomDetailsView(idiom: selectedIdiom)
                    .id(selectedIdiom.id)
            } else {
                Text("Select an idiom")
                    .toolbar(content: toolbarPlaceholder)
            }
        case .quizzes:
            selectedQuizView
        case .progress:
            Text("Progress Overview")
                .font(.title)
                .foregroundStyle(.secondary)
        @unknown default:
            fatalError("Unsupported sidebar item: \(selectedSidebarItem)")
        }
    }

    @ViewBuilder
    private var selectedQuizView: some View {
        switch quizzesViewModel.selectedQuiz {
        case .spelling:
            SpellingQuizView(wordCount: Int(quizzesViewModel.practiceWordCount))
        case .chooseDefinition:
            ChooseDefinitionView(wordCount: Int(quizzesViewModel.practiceWordCount))
        default:
            Text("Select a quiz")
        }
    }

    @ViewBuilder
    private func toolbarPlaceholder() -> some View {
        Button {
            // no action
        } label: {
            Image(systemName: "trash")
                .foregroundStyle(.secondary)
        }
        .disabled(true)

        Button {
            // no action
        } label: {
            Image(systemName: "heart")
                .foregroundStyle(.secondary)
        }
        .disabled(true)
    }
}
