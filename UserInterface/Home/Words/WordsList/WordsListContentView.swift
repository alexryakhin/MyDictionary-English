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

    init(viewModel: ViewModel) {
        self._viewModel = ObservedObject(wrappedValue: viewModel)
    }

    var body: some View {
        ScrollView {
            CustomSectionView(header: filterStateTitle, footer: viewModel.wordsCount) {
                if viewModel.wordsFiltered.isNotEmpty {
                    ListWithDivider(viewModel.wordsFiltered) { wordModel in
                        Button {
                            viewModel.handle(.showWordDetails(word: wordModel))
                        } label: {
                            WordListCellView(
                                model: .init(
                                    word: wordModel.word,
                                    isFavorite: wordModel.isFavorite,
                                    partOfSpeech: wordModel.partOfSpeech.rawValue
                                )
                            )
                            .padding(vertical: 12, horizontal: 16)
                            .background(Color.surface)
                            .contextMenu {
                                Button(role: .destructive) {
                                    viewModel.handle(.deleteWord(word: wordModel))
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .clippedWithBackground(.surface)
                }

                if viewModel.filterState == .search && viewModel.wordsFiltered.count < 10 {
                    Button {
                        addItem()
                    } label: {
                        Label("Add '\(viewModel.searchText.trimmingCharacters(in: .whitespacesAndNewlines))'", systemImage: "plus")
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .clippedWithPaddingAndBackground(.surface)
                    }
                }
            }
            .padding(vertical: 12, horizontal: 16)
        }
        .background(Color.background)
        .if(viewModel.words.isNotEmpty, transform: { view in
            view.searchable(text: $viewModel.searchText, placement: .navigationBarDrawer(displayMode: .always))
        })
        .toolbar {
            ToolbarItem {
                Button {
                    AnalyticsService.shared.logEvent(.addWordTapped)
                    addItem()
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
    }

    private func addItem() {
        if isShowingRating && viewModel.words.count > 15 {
            requestReview()
            isShowingRating = false
        }
        viewModel.handle(.showAddWord)
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
