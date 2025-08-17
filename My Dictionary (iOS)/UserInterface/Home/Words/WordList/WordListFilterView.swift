//
//  WordListFilterView.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/9/25.
//

import SwiftUI

struct WordListFilterView: View {
    @ObservedObject var viewModel: WordListViewModel
    @State private var showingTagManagement = false
    
    var body: some View {
        if viewModel.words.isNotEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    // All Words Filter
                    TagView(
                        text: Loc.FilterDisplay.allWords.localized,
                        color: .blue,
                        style: viewModel.filterState == .none ? .selected : .regular
                    )
                    .onTap {
                        viewModel.handle(.filterChanged(.none))
                    }

                    // Favorite Words Filter - only show if there are favorite words
                    if !viewModel.favoriteWords.isEmpty {
                        TagView(
                            text: Loc.FilterDisplay.favorite.localized,
                            color: .accentColor,
                            style: viewModel.filterState == .favorite ? .selected : .regular
                        )
                        .onTap {
                            viewModel.handle(.filterChanged(.favorite))
                        }
                    }

                    // Difficulty Filters - only show if there are words with that difficulty
                    let newWords = viewModel.words.filter { $0.difficultyLevel == .new }
                    if !newWords.isEmpty {
                        TagView(
                            text: Loc.FilterDisplay.new.localized,
                            color: .secondary,
                            style: viewModel.filterState == .new ? .selected : .regular
                        )
                        .onTap {
                            viewModel.handle(.filterChanged(.new))
                        }
                    }

                    let inProgressWords = viewModel.words.filter { $0.difficultyLevel == .inProgress }
                    if !inProgressWords.isEmpty {
                        TagView(
                            text: Loc.FilterDisplay.inProgress.localized,
                            color: .orange,
                            style: viewModel.filterState == .inProgress ? .selected : .regular
                        )
                        .onTap {
                            viewModel.handle(.filterChanged(.inProgress))
                        }
                    }

                    let needsReviewWords = viewModel.words.filter { $0.difficultyLevel == .needsReview }
                    if !needsReviewWords.isEmpty {
                        TagView(
                            text: Loc.FilterDisplay.needsReview.localized,
                            color: .red,
                            style: viewModel.filterState == .needsReview ? .selected : .regular
                        )
                        .onTap {
                            viewModel.handle(.filterChanged(.needsReview))
                        }
                    }

                    let masteredWords = viewModel.words.filter { $0.difficultyLevel == .mastered }
                    if !masteredWords.isEmpty {
                        TagView(
                            text: Loc.FilterDisplay.mastered.localized,
                            color: .accent,
                            style: viewModel.filterState == .mastered ? .selected : .regular
                        )
                        .onTap {
                            viewModel.handle(.filterChanged(.mastered))
                        }
                    }

                    // Tag Filters - only show tags that have associated words
                    ForEach(viewModel.availableTags, id: \.id) { tag in
                        let wordsWithTag = viewModel.words.filter { word in
                            word.tagsArray.contains { $0.id == tag.id }
                        }
                        if !wordsWithTag.isEmpty {
                            TagView(
                                text: tag.name ?? "",
                                color: tag.colorValue.color,
                                style: viewModel.selectedTag?.id == tag.id ? .selected : .regular
                            )
                            .onTap {
                                viewModel.handle(.filterChanged(.tag, tag: tag))
                            }
                        }
                    }

                    // Add Tag Button
                    TagView(
                        text: Loc.WordList.manageTags.localized,
                        systemImage: "plus",
                        color: .blue
                    )
                    .onTap {
                        showingTagManagement = true
                    }
                }
            }
            .scrollClipDisabled()
            .sheet(isPresented: $showingTagManagement) {
                TagManagementView()
            }
        }
    }
}
