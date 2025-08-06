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
        NavigationView {
            List {
                Section {
                    ForEach(viewModel.tags) { tag in
                        TagRowView(tag: tag) {
                            viewModel.handle(.editTag(tag))
                        } onDelete: {
                            viewModel.handle(.deleteTag(tag))
                        }
                    }
                } header: {
                    Text("Tags")
                } footer: {
                    Text("Tags help you organize your words. Each word can have up to 5 tags.")
                }
            }
            .navigationTitle("Manage Tags")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        viewModel.handle(.addTag)
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
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
}

struct TagRowView: View {
    let tag: CDTag
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            // Tag Color Indicator
            Circle()
                .fill(tag.colorValue.color)
                .frame(width: 12, height: 12)
            
            // Tag Name
            VStack(alignment: .leading, spacing: 2) {
                Text(tag.name ?? "")
                    .font(.body)
                    .fontWeight(.medium)
                
                Text("\(tag.wordsArray.count) words")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Edit Button
            Button {
                onEdit()
            } label: {
                Image(systemName: "pencil")
                    .foregroundColor(.blue)
            }
            .buttonStyle(.plain)

            // Delete Button
            Button {
                onDelete()
            } label: {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }
}
