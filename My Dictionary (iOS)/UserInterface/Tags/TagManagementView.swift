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
                header: Loc.Words.tags,
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
                        description: Text(Loc.Tags.addFirstTag)
                    )
                }
            } trailingContent: {
                HeaderButton(Loc.Tags.addTag, icon: "plus", size: .small, style: .borderedProminent) {
                    viewModel.handle(.addTag)
                }
            }
            .padding(vertical: 12, horizontal: 16)
            .if(isPad) { view in
                view
                    .frame(maxWidth: 550, alignment: .center)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .groupedBackground()
        .navigation(
            title: Loc.Tags.manageTags,
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
        .alert(Loc.Tags.deleteTag, isPresented: $viewModel.showingDeleteAlert) {
            Button(Loc.Actions.cancel, role: .cancel) { }
            Button(Loc.Actions.delete, role: .destructive) {
                viewModel.handle(.confirmDeleteTag)
            }
        } message: {
            Text(Loc.Tags.deleteTagCannotUndo)
        }
    }
}
