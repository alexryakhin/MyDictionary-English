//
//  AddEditTagView.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/9/25.
//

import SwiftUI

struct AddEditTagView: View {
    @Environment(\.dismiss) private var dismiss

    @StateObject var subscriptionService: SubscriptionService = .shared
    @ObservedObject var viewModel: TagManagementViewModel

    @State private var tagName = ""
    @State private var selectedColor: TagColor = .blue

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                CustomSectionView(header: "Tag Name", footer: "Choose a descriptive name for your tag") {
                    TextField("Type tag name...", text: $tagName)
                        .autocorrectionDisabled()
                        .padding(12)
                        .clippedWithBackground(Color.tertiarySystemFill, cornerRadius: 12)
                        .padding(.bottom, 12)
                    #if os(iOS)
                        .textInputAutocapitalization(.never)
                        .textContentType(.username)
                    #endif
                }
                CustomSectionView(header: "Tag Color", footer: "Select a color to help identify your tag") {
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
                }
            }
            .padding(.horizontal, 16)
        }
        .groupedBackground()
        .navigation(
            title: viewModel.isEditing ? "Edit Tag" : "New Tag",
            mode: .inline,
            trailingContent: {
                HeaderButton(icon: "xmark") {
                    dismiss()
                }
            }
        )
        .safeAreaInset(edge: .bottom) {
            ActionButton("Save", style: .borderedProminent) {
                if subscriptionService.isProUser {
                    saveTag()
                } else {
                    PaywallService.shared.isShowingPaywall = true
                }
            }
            .padding(vertical: 12, horizontal: 16)
        }
        .onAppear {
            if let editingTag = viewModel.editingTag {
                tagName = editingTag.name ?? ""
                selectedColor = editingTag.colorValue
            }
        }
        .withPaywall()
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
