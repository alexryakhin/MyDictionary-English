//
//  TagFilterView.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/9/25.
//

import SwiftUI

struct TagFilterView: View {
    @ObservedObject var viewModel: WordsListViewModel
    @State private var showingTagManagement = false
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
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
                    color: .red
                ) {
                    viewModel.handle(.filterChanged(.favorite))
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
                    .foregroundColor(.blue)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 16)
        }
        .sheet(isPresented: $showingTagManagement) {
            TagManagementView()
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
                .foregroundColor(isSelected ? .white : color)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    isSelected ? color : color.opacity(0.1)
                )
                .clipShape(Capsule())
        }
    }
}

#Preview {
    TagFilterView(viewModel: WordsListViewModel())
} 