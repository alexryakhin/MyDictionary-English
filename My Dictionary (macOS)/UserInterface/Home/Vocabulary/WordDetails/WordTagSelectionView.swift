//
//  WordTagSelectionView.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/9/25.
//

import SwiftUI
import Flow

struct WordTagSelectionView: View {

    @Environment(\.dismiss) private var dismiss
    @StateObject private var tagService: TagService = .shared
    @State private var isShowingAddTagSheet: Bool = false
    @ObservedObject var word: CDWord

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
                            let isSelected = word.tagsArray.contains { $0.id == tag.id }
                            HeaderButton(
                                tag.name.orEmpty,
                                color: tag.colorValue.color,
                                style: isSelected ? .borderedProminent : .bordered
                            ) {
                                toggleTag(tag)
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
        .sheet(isPresented: $isShowingAddTagSheet) {
            AddEditTagView(viewModel: .init())
        }
    }

    private func toggleTag(_ tag: CDTag) {
        do {
            if word.tagsArray.contains(where: { $0.id == tag.id }) {
                try tagService.removeTagFromWord(tag, word: word)
                AnalyticsService.shared.logEvent(.tagRemovedFromWord)
            } else {
                try tagService.addTagToWord(tag, word: word)
                AnalyticsService.shared.logEvent(.tagAddedToWord)
            }
        } catch {
            errorReceived(error)
        }
    }
}
