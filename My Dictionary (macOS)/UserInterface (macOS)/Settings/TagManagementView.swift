//
//  TagManagementView.swift
//  My Dictionary (macOS)
//
//  Created by Aleksandr Riakhin on 3/9/25.
//

import SwiftUI

struct TagManagementView: View {
    @StateObject private var viewModel = TagManagementViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Manage Tags")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button("Done") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(20)
            .background(Color(.windowBackgroundColor))
            .overlay(alignment: .bottom) {
                Divider()
            }
            
            // Content
            VStack(spacing: 0) {
                if viewModel.tags.isEmpty {
                    emptyStateView
                } else {
                    tagsListView
                }
            }
            .background(Color(.windowBackgroundColor))
        }
        .frame(width: 500, height: 400)
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
        .alert("Error", isPresented: $viewModel.showingErrorAlert) {
            Button("OK") { }
        } message: {
            Text(viewModel.errorMessage)
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            VStack(spacing: 16) {
                Image(systemName: "tag")
                    .font(.system(size: 60))
                    .foregroundStyle(.accent.gradient)
                
                Text("No Tags Yet")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Tags help you organize your words.\nEach word can have up to 5 tags.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .padding(.horizontal, 32)
            
            Button {
                viewModel.handle(.addTag)
            } label: {
                Label("Create Your First Tag", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.accent.gradient)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 32)
            
            Spacer()
        }
    }
    
    private var tagsListView: some View {
        VStack(spacing: 0) {
            // Add Tag Button
            HStack {
                Button {
                    viewModel.handle(.addTag)
                } label: {
                    Label("Add Tag", systemImage: "plus.circle.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.accent.gradient)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }
            .padding(20)
            
            // Tags List
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.tags) { tag in
                        TagRowView(tag: tag) {
                            viewModel.handle(.editTag(tag))
                        } onDelete: {
                            viewModel.handle(.deleteTag(tag))
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
    }
}

struct TagRowView: View {
    let tag: CDTag
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Tag Color Indicator
            Circle()
                .fill(tag.colorValue.color)
                .frame(width: 16, height: 16)
            
            // Tag Info
            VStack(alignment: .leading, spacing: 4) {
                Text(tag.name ?? "")
                    .font(.body)
                    .fontWeight(.medium)
                
                Text("\(tag.wordsArray.count) words")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            // Action Buttons
            HStack(spacing: 8) {
                Button {
                    onEdit()
                } label: {
                    Image(systemName: "pencil")
                        .font(.caption)
                        .foregroundStyle(.blue)
                        .frame(width: 32, height: 32)
                        .background(.blue.opacity(0.1))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)

                Button {
                    onDelete()
                } label: {
                    Image(systemName: "trash")
                        .font(.caption)
                        .foregroundStyle(.red)
                        .frame(width: 32, height: 32)
                        .background(.red.opacity(0.1))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .background(Color(.secondarySystemFill))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

#Preview {
    TagManagementView()
} 
