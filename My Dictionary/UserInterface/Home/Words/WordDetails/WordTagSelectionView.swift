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
        ScrollView {
            CustomSectionView(
                header: "Select Tags",
                footer: "You can select up to 5 tags per word. Tap a tag to select or deselect it."
            ) {
                if tagService.tags.isEmpty {
                    ContentUnavailableView(
                        "No Tags Yet",
                        systemImage: "tag",
                        description: Text("Add a tag to start using it.")
                    )
                    .padding(.vertical, 16)
                } else {
                    HFlow(alignment: .top, spacing: 8) {
                        ForEach(tagService.tags) { tag in
                            let isSelected = word.tagsArray.contains { $0.id == tag.id }
                            HeaderButton(
                                text: tag.name.orEmpty,
                                style: isSelected ? .borderedProminent : .bordered
                            ) {
                                toggleTag(tag)
                            }
                            .tint(tag.colorValue.color)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, 12)
                }
            } trailingContent: {
                HeaderButton(text: "Create tags", icon: "tag", style: .borderedProminent) {
                    isShowingAddTagSheet.toggle()
                }
            }
            .padding(.horizontal, 16)
        }
        .groupedBackground()
        .navigation(
            title: "Add Tags",
            mode: .inline,
            trailingContent: {
                HeaderButton(text: "Done", icon: "checkmark") {
                    dismiss()
                }
            }
        )
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
