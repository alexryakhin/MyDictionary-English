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
                    let newWords = viewModel.words.filter { $0.difficultyLevel == .new }
                    if !newWords.isEmpty {
                        FilterChip(
                            title: "New",
                            isSelected: viewModel.filterState == .new,
                            color: .secondary
                        ) {
                            viewModel.handle(.filterChanged(.new))
                        }
                    }

                    let inProgressWords = viewModel.words.filter { $0.difficultyLevel == .inProgress }
                    if !inProgressWords.isEmpty {
                        FilterChip(
                            title: "In Progress",
                            isSelected: viewModel.filterState == .inProgress,
                            color: .orange
                        ) {
                            viewModel.handle(.filterChanged(.inProgress))
                        }
                    }

                    let needsReviewWords = viewModel.words.filter { $0.difficultyLevel == .needsReview }
                    if !needsReviewWords.isEmpty {
                        FilterChip(
                            title: "Needs Review",
                            isSelected: viewModel.filterState == .needsReview,
                            color: .red
                        ) {
                            viewModel.handle(.filterChanged(.needsReview))
                        }
                    }

                    let masteredWords = viewModel.words.filter { $0.difficultyLevel == .mastered }
                    if !masteredWords.isEmpty {
                        FilterChip(
                            title: "Mastered",
                            isSelected: viewModel.filterState == .mastered,
                            color: .green
                        ) {
                            viewModel.handle(.filterChanged(.mastered))
                        }
                    }

                    // Tag Filters - only show tags that have associated words
                    ForEach(viewModel.availableTags, id: \.id) { tag in
                        let wordsWithTag = viewModel.words.filter { word in
                            word.tagsArray.contains { $0.id == tag.id }
                        }
                        if !wordsWithTag.isEmpty {
                            FilterChip(
                                title: tag.name ?? "",
                                isSelected: viewModel.selectedTag?.id == tag.id,
                                color: tag.colorValue.color
                            ) {
                                viewModel.handle(.filterChanged(.tag, tag: tag))
                            }
                        }
                    }

                    // Add Tag Button
                    Button {
                        showingTagManagement = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "plus")
                                .font(.caption)
                            Text("Manage Tags")
                                .font(.caption)
                        }
                        .foregroundStyle(.blue)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.2))
                        .clipShape(Capsule())
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

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(isSelected ? .white : color)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    isSelected ? color : color.opacity(0.2)
                )
                .clipShape(Capsule())
        }
    }
}
