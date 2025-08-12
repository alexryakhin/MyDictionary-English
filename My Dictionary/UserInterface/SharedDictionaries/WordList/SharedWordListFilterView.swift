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
                    FilterChip(
                        title: "All Words",
                        isSelected: viewModel.filterState == .none,
                        color: .blue
                    ) {
                        viewModel.handle(.filterChanged(.none))
                    }

                    // Favorite Words Filter - only show if there are favorite words
                    if !viewModel.favoriteWords.isEmpty {
                        FilterChip(
                            title: "Favorite",
                            isSelected: viewModel.filterState == .favorite,
                            color: .accentColor
                        ) {
                            viewModel.handle(.filterChanged(.favorite))
                        }
                    }

                    // Difficulty Filters - only show if there are words with that difficulty
                    let newWords = viewModel.words.filter { viewModel.getDifficultyForWord($0) == .new }
                    if !newWords.isEmpty {
                        FilterChip(
                            title: "New",
                            isSelected: viewModel.filterState == .new,
                            color: .secondary
                        ) {
                            viewModel.handle(.filterChanged(.new))
                        }
                    }

                    let inProgressWords = viewModel.words.filter { viewModel.getDifficultyForWord($0) == .inProgress }
                    if !inProgressWords.isEmpty {
                        FilterChip(
                            title: "In Progress",
                            isSelected: viewModel.filterState == .inProgress,
                            color: .orange
                        ) {
                            viewModel.handle(.filterChanged(.inProgress))
                        }
                    }

                    let needsReviewWords = viewModel.words.filter { viewModel.getDifficultyForWord($0) == .needsReview }
                    if !needsReviewWords.isEmpty {
                        FilterChip(
                            title: "Needs Review",
                            isSelected: viewModel.filterState == .needsReview,
                            color: .red
                        ) {
                            viewModel.handle(.filterChanged(.needsReview))
                        }
                    }

                    let masteredWords = viewModel.words.filter { viewModel.getDifficultyForWord($0) == .mastered }
                    if !masteredWords.isEmpty {
                        FilterChip(
                            title: "Mastered",
                            isSelected: viewModel.filterState == .mastered,
                            color: .green
                        ) {
                            viewModel.handle(.filterChanged(.mastered))
                        }
                    }
                }
            }
            .scrollClipDisabled()
        }
    }
}
