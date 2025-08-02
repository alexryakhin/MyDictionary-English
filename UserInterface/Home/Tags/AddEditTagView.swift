//
//  AddEditTagView.swift
//  My Dictionary
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
        NavigationView {
            Form {
                Section {
                    TextField("Tag Name", text: $tagName)
                        .textFieldStyle(.roundedBorder)
                } header: {
                    Text("Tag Name")
                } footer: {
                    Text("Choose a descriptive name for your tag")
                }
                
                Section {
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
                    .padding(.vertical, 8)
                } header: {
                    Text("Tag Color")
                } footer: {
                    Text("Select a color to help identify your tag")
                }
            }
            .navigationTitle(viewModel.isEditing ? "Edit Tag" : "New Tag")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveTag()
                    }
                    .disabled(tagName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear {
                if let editingTag = viewModel.editingTag {
                    tagName = editingTag.name ?? ""
                    selectedColor = editingTag.colorValue
                }
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
            Circle()
                .fill(color.color)
                .frame(width: 40, height: 40)
                .overlay(
                    Circle()
                        .stroke(isSelected ? Color.primary : Color.clear, lineWidth: 3)
                )
                .overlay(
                    Image(systemName: "checkmark")
                        .foregroundColor(.white)
                        .font(.caption)
                        .fontWeight(.bold)
                        .opacity(isSelected ? 1 : 0)
                )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    AddEditTagView(viewModel: TagManagementViewModel())
} 
