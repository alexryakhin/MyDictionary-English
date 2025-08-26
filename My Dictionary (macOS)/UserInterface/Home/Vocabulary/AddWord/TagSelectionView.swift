//
//  TagSelectionView.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/9/25.
//

import SwiftUI
import Flow

struct TagSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var tagService: TagService = .shared
    @State private var isShowingAddTagSheet: Bool = false

    @Binding var selectedTags: [CDTag]

    var body: some View {
        ScrollViewWithCustomNavBar {
                    CustomSectionView(
            header: Loc.Tags.TagSelection.selectTags,
                footer: Loc.Tags.TagSelection.youCanSelectUpTo5Tags
            ) {
                if tagService.tags.isEmpty {
                                    ContentUnavailableView(
                    Loc.Tags.TagSelection.noTagsYet,
                        systemImage: "tag",
                        description: Text(Loc.Tags.addTagToStartUsing)
                    )
                    .padding(.vertical, 16)
                } else {
                    HFlow(alignment: .top, spacing: 8) {
                        ForEach(tagService.tags) { tag in
                            let isSelected = selectedTags.contains { $0.id == tag.id }
                            HeaderButton(
                                tag.name.orEmpty,
                                color: tag.colorValue.color,
                                size: .small,
                                style: isSelected ? .borderedProminent : .bordered
                            ) {
                                if let index = selectedTags.firstIndex(where: { $0.id == tag.id }) {
                                    selectedTags.remove(at: index)
                                } else {
                                    selectedTags.append(tag)
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, 12)
                }
            } trailingContent: {
                HeaderButton(Loc.Tags.createTags, icon: "tag", size: .small, style: .borderedProminent) {
                    isShowingAddTagSheet.toggle()
                }
            }
            .padding(12)
        } navigationBar: {
            NavigationBarView(title: Loc.Tags.addTags)
        }
        .groupedBackground()
                        .navigationTitle(Loc.Tags.addTags)
        .sheet(isPresented: $isShowingAddTagSheet) {
            AddEditTagView(viewModel: .init())
        }
    }
}

struct TagSelectionRow: View {
    let tag: CDTag
    let isSelected: Bool
    let action: VoidHandler
    
    var body: some View {
        Button(action: action) {
            HStack {
                // Tag Color Indicator
                Circle()
                    .fill(tag.colorValue.color)
                    .frame(width: 12, height: 12)
                
                // Tag Name
                Text(tag.name ?? "")
                    .foregroundStyle(.primary)
                
                Spacer()
                
                // Selection Indicator
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.accent)
                        .fontWeight(.bold)
                }
            }
        }
        .buttonStyle(.plain)
    }
}
