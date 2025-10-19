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
    @StateObject var viewModel = TagManagementViewModel()

    @State private var tagName = ""
    @State private var selectedColor: TagColor = .blue

    var body: some View {
        ScrollViewWithCustomNavBar {
            VStack(spacing: 16) {
                CustomSectionView(header: Loc.Tags.tagName, footer: Loc.Tags.tagNameHelp) {
                    TextField("Type tag name...", text: $tagName)
                        .textFieldStyle(.plain)
                        .autocorrectionDisabled()
                        .padding(12)
                        .clippedWithBackground(Color.tertiarySystemFill, in: .rect(cornerRadius: 12))
                        .padding(.bottom, 12)
                }
                CustomSectionView(header: Loc.Tags.tagColor, footer: Loc.Tags.tagColorHelp) {
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
            .padding(12)
        } navigationBar: {
            NavigationBarView(
                title: viewModel.isEditing ? Loc.Tags.editTag : Loc.Tags.newTag,
                trailingContent: {
                    HeaderButton(Loc.Actions.save, style: .borderedProminent) {
                        if subscriptionService.isProUser || viewModel.tags.count < 5 {
                            saveTag()
                        } else {
                            PaywallService.shared.isShowingPaywall = true
                        }
                    }
                    .help(Loc.Actions.save)
                }
            )
        }
        .groupedBackground()
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
