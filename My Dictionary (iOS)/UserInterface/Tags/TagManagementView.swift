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
        ScrollView {
            CustomSectionView(
                header: Loc.Words.tags.localized,
                footer: Loc.Tags.tagsHelpText.localized,
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
                        Loc.Tags.noTagsYet.localized,
                        systemImage: "tag.fill",
                        description: Text(Loc.Tags.addFirstTag.localized)
                    )
                }
            } trailingContent: {
                HeaderButton(Loc.Tags.addTag.localized, icon: "plus", size: .small, style: .borderedProminent) {
                    viewModel.handle(.addTag)
                }
            }
            .padding(.horizontal, 16)
        }
        .groupedBackground()
        .navigation(
            title: Loc.Tags.manageTags.localized,
            mode: .inline,
            trailingContent: {
                HeaderButton(icon: "xmark") {
                    dismiss()
                }
            }
        )
        .sheet(isPresented: $viewModel.showingAddEditSheet) {
            AddEditTagView(viewModel: viewModel)
        }
        .alert(Loc.Tags.deleteTag.localized, isPresented: $viewModel.showingDeleteAlert) {
            Button(Loc.Actions.cancel.localized, role: .cancel) { }
            Button(Loc.Actions.delete.localized, role: .destructive) {
                viewModel.handle(.confirmDeleteTag)
            }
        } message: {
            Text(Loc.Tags.deleteTagCannotUndo.localized)
        }
    }
}
