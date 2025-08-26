//
//  TagManagementView.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/9/25.
//

import SwiftUI

struct TagManagementView: View {
    @StateObject private var viewModel = TagManagementViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollViewWithCustomNavBar {
            CustomSectionView(
                header: Loc.Tags.manageTags,
                footer: Loc.Tags.tagsHelpText,
                hPadding: 0
            ) {
                if viewModel.tags.isNotEmpty {
                    ListWithDivider(viewModel.tags) { tag in
                        TagRowView(tag: tag) {
                            viewModel.handle(.editTag(tag))
                        } onDelete: {
                            viewModel.handle(.deleteTag(tag))
                        }
                        .padding(vertical: 8, horizontal: 16)
                    }
                } else {
                    ContentUnavailableView(
                        Loc.Tags.noTagsYet,
                        systemImage: "tag.fill",
                        description: Text(Loc.Tags.addFirstTagDescription)
                    )
                }
            } trailingContent: {
                HeaderButton(Loc.Tags.addTag, icon: "plus", size: .small, style: .borderedProminent) {
                    viewModel.handle(.addTag)
                }
            }
            .padding(12)
        } navigationBar: {
            NavigationBarView(title: Loc.Tags.manageTags)
        }
        .groupedBackground()
        .sheet(isPresented: $viewModel.showingAddEditSheet) {
            AddEditTagView(viewModel: viewModel)
        }
    }
}
