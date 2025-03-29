import SwiftUI
import CoreUserInterface__macOS_

public struct MainTabView: View {

    @State private var selectedSidebarItem: SidebarItem = .words
    @StateObject private var wordsViewModel = WordsViewModel()
    @StateObject private var idiomsViewModel = IdiomsViewModel()
//    @StateObject private var quizzesViewModel = QuizzesViewModel()

    public init() { }

    public var body: some View {
        NavigationSplitView {
            List(selection: $selectedSidebarItem) {
                Section {
                    ForEach(SidebarItem.allCases, id: \.self) { item in
                        NavigationLink(value: item) {
                            Label {
                                Text(item.title)
                            } icon: {
                                item.image
                            }
                            .padding(.vertical, 8)
                            .font(.title3)
                        }
                    }
                } header: {
                    Text("My Dictionary")
                        .font(.title2)
                        .bold()
                        .padding(.vertical, 16)
                }
            }
        } content: {
            switch selectedSidebarItem {
            case .words:
                WordsListView(viewModel: _wordsViewModel)
            case .idioms:
//                Text("IdiomsListView")
                IdiomsListView(viewModel: _idiomsViewModel)
            case .quizzes:
                Text("QuizzesView")
//                QuizzesView(viewModel: quizzesViewModel)
            }
        } detail: {
            switch selectedSidebarItem {
            case .words:
                if wordsViewModel.selectedWord == nil {
                    Text("Select an item")
                } else {
                    WordDetailsView(viewModel: wordsViewModel)
                }
            case .idioms:
                Text("Select an item")
            case .quizzes:
                Text("Select an item")
            }
        }
        .fontDesign(.rounded)
    }
}
