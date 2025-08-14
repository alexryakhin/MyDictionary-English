//
//  SharedWordListFilterView.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/9/25.
//

import SwiftUI

struct SharedWordListFilterView: View {
    @ObservedObject var viewModel: SharedWordListViewModel
    
    var body: some View {
        if viewModel.words.isNotEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    // All Words Filter
                    TagView(
                        text: "All Words",
                        color: .blue,
                        style: viewModel.filterState == .none ? .selected : .regular
                    )
                    .onTap {
                        viewModel.handle(.filterChanged(.none))
                    }

                    // Favorite Words Filter - only show if there are favorite words
                    if !viewModel.favoriteWords.isEmpty {
                        TagView(
                            text: "Favorite",
                            color: .accentColor,
                            style: viewModel.filterState == .favorite ? .selected : .regular
                        )
                        .onTap {
                            viewModel.handle(.filterChanged(.favorite))
                        }
                    }

                    // Difficulty Filters - only show if there are words with that difficulty
                    let newWords = viewModel.words.filter { viewModel.getDifficultyForWord($0) == .new }
                    if !newWords.isEmpty {
                        TagView(
                            text: "New",
                            color: .secondary,
                            style: viewModel.filterState == .new ? .selected : .regular
                        )
                        .onTap {
                            viewModel.handle(.filterChanged(.new))
                        }
                    }

                    let inProgressWords = viewModel.words.filter { viewModel.getDifficultyForWord($0) == .inProgress }
                    if !inProgressWords.isEmpty {
                        TagView(
                            text: "In Progress",
                            color: .orange,
                            style: viewModel.filterState == .inProgress ? .selected : .regular
                        )
                        .onTap {
                            viewModel.handle(.filterChanged(.inProgress))
                        }
                    }

                    let needsReviewWords = viewModel.words.filter { viewModel.getDifficultyForWord($0) == .needsReview }
                    if !needsReviewWords.isEmpty {
                        TagView(
                            text: "Needs Review",
                            color: .red,
                            style: viewModel.filterState == .needsReview ? .selected : .regular
                        )
                        .onTap {
                            viewModel.handle(.filterChanged(.needsReview))
                        }
                    }

                    let masteredWords = viewModel.words.filter { viewModel.getDifficultyForWord($0) == .mastered }
                    if !masteredWords.isEmpty {
                        TagView(
                            text: "Mastered",
                            color: .accent,
                            style: viewModel.filterState == .mastered ? .selected : .regular
                        )
                        .onTap {
                            viewModel.handle(.filterChanged(.mastered))
                        }
                    }
                }
            }
            .scrollClipDisabled()
        }
    }
}
