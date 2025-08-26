//
//  VocabularyListFilterView.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/9/25.
//

import SwiftUI

struct VocabularyListFilterView: View {
    @ObservedObject var wordListViewModel: WordListViewModel
    @ObservedObject var idiomListViewModel: IdiomListViewModel
    
    @State private var showingTagManagement = false
    
    var body: some View {
        if wordListViewModel.words.isNotEmpty || idiomListViewModel.idioms.isNotEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    // All Words Filter
                    TagView(
                        text: Loc.FilterDisplay.all,
                        color: .blue,
                        style: wordListViewModel.filterState == .none ? .selected : .regular
                    )
                    .onTap {
                        handleFilterChanged(.none)
                    }

                    TagView(
                        text: Loc.FilterDisplay.favorite,
                        color: .accentColor,
                        style: wordListViewModel.filterState == .favorite ? .selected : .regular
                    )
                    .onTap {
                        handleFilterChanged(.favorite)
                    }

                    TagView(
                        text: Loc.FilterDisplay.new,
                        color: .secondary,
                        style: wordListViewModel.filterState == .new ? .selected : .regular
                    )
                    .onTap {
                        handleFilterChanged(.new)
                    }

                    TagView(
                        text: Loc.FilterDisplay.inProgress,
                        color: .orange,
                        style: wordListViewModel.filterState == .inProgress ? .selected : .regular
                    )
                    .onTap {
                        handleFilterChanged(.inProgress)
                    }

                    TagView(
                        text: Loc.FilterDisplay.needsReview,
                        color: .red,
                        style: wordListViewModel.filterState == .needsReview ? .selected : .regular
                    )
                    .onTap {
                        handleFilterChanged(.needsReview)
                    }

                    TagView(
                        text: Loc.FilterDisplay.mastered,
                        color: .accent,
                        style: wordListViewModel.filterState == .mastered ? .selected : .regular
                    )
                    .onTap {
                        handleFilterChanged(.mastered)
                    }

                    // Tag Filters - only show tags that have associated words
                    ForEach(wordListViewModel.availableTags, id: \.id) { tag in
                        TagView(
                            text: tag.name ?? "",
                            color: tag.colorValue.color,
                            style: wordListViewModel.selectedTag?.id == tag.id ? .selected : .regular
                        )
                        .onTap {
                            handleFilterChanged(.tag, tag: tag)
                        }
                    }

                    // Add Tag Button
                    TagView(
                        text: Loc.Words.WordList.manageTags,
                        systemImage: "plus",
                        color: .blue
                    )
                    .onTap {
                        showingTagManagement = true
                    }
                }
                .padding(.horizontal, 16)
            }
            .sheet(isPresented: $showingTagManagement) {
                TagManagementView()
            }
        }
    }

    private func handleFilterChanged(_ filter: FilterCase, tag: CDTag? = nil) {
        wordListViewModel.handle(.filterChanged(filter, tag: tag))
        idiomListViewModel.handle(.filterChanged(filter, tag: tag))
    }
}
