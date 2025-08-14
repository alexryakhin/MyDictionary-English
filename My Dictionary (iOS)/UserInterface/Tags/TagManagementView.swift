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
                header: "Tags",
                footer: "Tags help you organize your words. Each word can have up to 5 tags.",
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
                        "No Tags added yet",
                        systemImage: "tag.fill",
                        description: Text("Add your first tag by tapping the button above.")
                    )
                }
            } trailingContent: {
                HeaderButton("Add Tag", icon: "plus", size: .small, style: .borderedProminent) {
                    viewModel.handle(.addTag)
                }
            }
            .padding(.horizontal, 16)
        }
        .groupedBackground()
        .navigation(
            title: "Manage Tags",
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
        .alert("Delete Tag", isPresented: $viewModel.showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                viewModel.handle(.confirmDeleteTag)
            }
        } message: {
            Text("Are you sure you want to delete this tag? This action cannot be undone.")
        }
    }
}
