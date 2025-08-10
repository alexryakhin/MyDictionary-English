//
//  TagFilterView.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/9/25.
//

import SwiftUI

struct TagFilterView: View {
    @ObservedObject var viewModel: WordListViewModel
    @State private var showingTagManagement = false
    
    var body: some View {
        if viewModel.words.isNotEmpty {
            VStack(spacing: 8) {
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

                        // Favorite Words Filter
                        FilterChip(
                            title: "Favorite",
                            isSelected: viewModel.filterState == .favorite,
                            color: .accentColor
                        ) {
                            viewModel.handle(.filterChanged(.favorite))
                        }

                        // Difficulty Filters
                        FilterChip(
                            title: "New",
                            isSelected: viewModel.filterState == .new,
                            color: .secondary
                        ) {
                            viewModel.handle(.filterChanged(.new))
                        }

                        FilterChip(
                            title: "In Progress",
                            isSelected: viewModel.filterState == .inProgress,
                            color: .orange
                        ) {
                            viewModel.handle(.filterChanged(.inProgress))
                        }

                        FilterChip(
                            title: "Needs Review",
                            isSelected: viewModel.filterState == .needsReview,
                            color: .red
                        ) {
                            viewModel.handle(.filterChanged(.needsReview))
                        }

                        FilterChip(
                            title: "Mastered",
                            isSelected: viewModel.filterState == .mastered,
                            color: .green
                        ) {
                            viewModel.handle(.filterChanged(.mastered))
                        }

                        // Tag Filters
                        ForEach(viewModel.availableTags, id: \.id) { tag in
                            FilterChip(
                                title: tag.name ?? "",
                                isSelected: viewModel.selectedTag?.id == tag.id,
                                color: tag.colorValue.color
                            ) {
                                viewModel.handle(.filterChanged(.tag, tag: tag))
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
            }
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
