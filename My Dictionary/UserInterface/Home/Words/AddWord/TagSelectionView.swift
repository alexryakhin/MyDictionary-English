//
//  TagSelectionView.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/9/25.
//

import SwiftUI

struct TagSelectionView: View {
    @ObservedObject var viewModel: AddWordViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    ForEach(viewModel.availableTags) { tag in
                        TagSelectionRow(
                            tag: tag,
                            isSelected: viewModel.selectedTags.contains { $0.id == tag.id }
                        ) {
                            viewModel.handle(.toggleTag(tag))
                        }
                    }
                } header: {
                    Text("Select Tags")
                } footer: {
                    Text("You can select up to 5 tags per word. Tap a tag to select or deselect it.")
                }
            }
            .navigationTitle("Add Tags")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct TagSelectionRow: View {
    let tag: CDTag
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                // Tag Color Indicator
                Circle()
                    .fill(tag.colorValue.color)
                    .frame(width: 12, height: 12)
                
                // Tag Name
                Text(tag.name ?? "")
                    .foregroundColor(.primary)
                
                Spacer()
                
                // Selection Indicator
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundColor(.blue)
                        .fontWeight(.bold)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    TagSelectionView(viewModel: AddWordViewModel())
} 