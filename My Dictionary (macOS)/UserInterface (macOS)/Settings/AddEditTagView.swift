//
//  AddEditTagView.swift
//  My Dictionary (macOS)
//
//  Created by Aleksandr Riakhin on 3/9/25.
//

import SwiftUI

struct AddEditTagView: View {
    @ObservedObject var viewModel: TagManagementViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var tagName = ""
    @State private var selectedColor: TagColor = .blue
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(viewModel.isEditing ? "Edit Tag" : "New Tag")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                HStack(spacing: 12) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Save") {
                        saveTag()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(tagName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .padding(20)
            .background(Color(.windowBackgroundColor))
            .overlay(alignment: .bottom) {
                Divider()
            }
            
            // Content
            ScrollView {
                VStack(spacing: 24) {
                    // Tag Name Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Tag Name")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        TextField("Enter tag name...", text: $tagName)
                            .textFieldStyle(.roundedBorder)
                            .font(.body)
                        
                        Text("Choose a descriptive name for your tag")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(20)
                    .background(Color(.secondarySystemFill))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    // Tag Color Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Tag Color")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                            ForEach(TagColor.allCases, id: \.self) { color in
                                ColorSelectionButton(
                                    color: color,
                                    isSelected: selectedColor == color
                                ) {
                                    selectedColor = color
                                }
                            }
                        }
                        
                        Text("Select a color to help identify your tag")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(20)
                    .background(Color(.secondarySystemFill))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(20)
            }
        }
        .frame(width: 400, height: 500)
        .onAppear {
            if let editingTag = viewModel.editingTag {
                tagName = editingTag.name ?? ""
                selectedColor = editingTag.colorValue
            }
        }
    }
    
    private func saveTag() {
        let trimmedName = tagName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if viewModel.isEditing {
            viewModel.handle(.updateTag(name: trimmedName, color: selectedColor))
        } else {
            viewModel.handle(.saveTag(name: trimmedName, color: selectedColor))
        }
        
        dismiss()
    }
}

struct ColorSelectionButton: View {
    let color: TagColor
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Circle()
                    .fill(color.color)
                    .frame(width: 48, height: 48)
                    .overlay(
                        Circle()
                            .stroke(isSelected ? Color.primary : Color.clear, lineWidth: 3)
                    )
                    .overlay(
                        Image(systemName: "checkmark")
                            .foregroundStyle(.white)
                            .font(.caption)
                            .fontWeight(.bold)
                            .opacity(isSelected ? 1 : 0)
                    )
                
                Text(color.displayName)
                    .font(.caption)
                    .foregroundStyle(isSelected ? .primary : .secondary)
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    AddEditTagView(viewModel: TagManagementViewModel())
} 
