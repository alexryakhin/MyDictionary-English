//
//  WordsListContentView.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import SwiftUI
import StoreKit

struct WordsListContentView: View {

    typealias ViewModel = WordsListViewModel

    @AppStorage(UDKeys.isShowingRating) var isShowingRating: Bool = true
    @AppStorage(UDKeys.isShowingOnboarding) var isShowingOnboarding: Bool = true
    @Environment(\.requestReview) var requestReview
    @ObservedObject var viewModel: ViewModel

    @State private var showingAddWord = false
    @State private var selectedWord: CDWord?

    init(viewModel: ViewModel) {
        self._viewModel = ObservedObject(wrappedValue: viewModel)
    }

    var body: some View {
        Group {
            if viewModel.wordsFiltered.isNotEmpty {
                ScrollView {
                    CustomSectionView(header: filterStateTitle, footer: viewModel.wordsCount) {
                        ListWithDivider(viewModel.wordsFiltered) { wordModel in
                            NavigationLink {
                                WordDetailsContentView(word: wordModel)
                            } label: {
                                WordListCellView(
                                    model: .init(
                                        word: wordModel.wordItself ?? "",
                                        isFavorite: wordModel.isFavorite,
                                        partOfSpeech: wordModel.partOfSpeech ?? ""
                                    )
                                )
                                .clippedWithPaddingAndBackground()
                                .contextMenu {
                                    Button(role: .destructive) {
                                        viewModel.handle(.deleteWord(word: wordModel))
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                        }
                        .clippedWithBackground()
                    }
                    .padding(vertical: 12, horizontal: 16)

                    if viewModel.filterState == .search && viewModel.wordsFiltered.count < 10 {
                        Button {
                            showingAddWord.toggle()
                        } label: {
                            Label("Add '\(viewModel.searchText.trimmingCharacters(in: .whitespacesAndNewlines))'", systemImage: "plus")
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .clippedWithPaddingAndBackground()
                        }
                    }
                }
                .background(Color(.systemGroupedBackground).ignoresSafeArea())
            } else {
                ContentUnavailableView(
                    "No words yet",
                    systemImage: "textformat",
                    description: Text("Begin to add words to your list by tapping on plus icon in upper left corner")
                )
                .background(Color(.systemGroupedBackground))
            }
        }
        .navigationTitle("Words")
        .if(viewModel.words.isNotEmpty, transform: { view in
            view.searchable(text: $viewModel.searchText, placement: .navigationBarDrawer(displayMode: .always))
        })
        .toolbar {
            ToolbarItem {
                Button {
                    AnalyticsService.shared.logEvent(.addWordTapped)
                    showingAddWord = true
                } label: {
                    Label("Add Item", systemImage: "plus")
                }
            }
            ToolbarItem(placement: .navigationBarLeading) {
                Menu {
                    Picker("Sort", selection: _viewModel.projectedValue.sortingState) {
                        ForEach(SortingCase.allCases, id: \.self) { item in
                            Text(item.rawValue)
                                .tag(item)
                        }
                    }
                    .pickerStyle(.menu)
                    Picker("Filter", selection: _viewModel.projectedValue.filterState) {
                        ForEach(FilterCase.availableCases, id: \.self) { item in
                            Text(item.rawValue)
                                .tag(item)
                        }
                    }
                    .pickerStyle(.menu)
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .onAppear {
            AnalyticsService.shared.logEvent(.wordsListOpened)
        }
        .sheet(isPresented: $isShowingOnboarding) {
            isShowingOnboarding = false
        } content: {
            OnboardingView()
        }
        .sheet(isPresented: $showingAddWord) {
            AddWordContentView(inputWord: viewModel.searchText)
        }
        .alert(isPresented: $viewModel.isShowingAlert) {
            Alert(
                title: Text(viewModel.alertModel.title),
                message: Text(viewModel.alertModel.message ?? ""),
                primaryButton: .default(Text(viewModel.alertModel.actionText ?? "OK")) {
                    viewModel.alertModel.action?()
                },
                secondaryButton: viewModel.alertModel.destructiveActionText != nil ? .destructive(Text(viewModel.alertModel.destructiveActionText!)) {
                    viewModel.alertModel.destructiveAction?()
                } : .cancel()
            )
        }

    }

    private var filterStateTitle: LocalizedStringKey {
        switch viewModel.filterState {
        case .none:
            return "All words"
        case .favorite:
            return "Favorites"
        case .search:
            return "Found"
        }
    }
}
