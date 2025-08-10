//
//  AddEditTagView.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/9/25.
//

import SwiftUI
import RevenueCatUI

struct AddEditTagView: View {
    @Environment(\.dismiss) private var dismiss

    @StateObject var subscriptionService: SubscriptionService = .shared
    @ObservedObject var viewModel: TagManagementViewModel

    @State private var tagName = ""
    @State private var selectedColor: TagColor = .blue
    @State private var isShowingPaywall: Bool = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                CustomSectionView(header: "Tag Name", footer: "Choose a descriptive name for your tag") {
                    TextField("Type tag name...", text: $tagName)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .textContentType(.username)
                        .padding(12)
                        .clippedWithBackground(Color(.tertiarySystemFill), cornerRadius: 12)
                        .padding(.bottom, 12)
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
            Button {
                if subscriptionService.isProUser {
                    saveTag()
                } else {
                    isShowingPaywall = true
                }
            } label: {
                Text("Save")
                    .fontWeight(.semibold)
                    .padding(12)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .padding(12)
        }
        .onAppear {
            if let editingTag = viewModel.editingTag {
                tagName = editingTag.name ?? ""
                selectedColor = editingTag.colorValue
            }
        }
        .sheet(isPresented: $isShowingPaywall) {
            PaywallView()
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
                        .foregroundStyle(.white)
                        .font(.caption)
                        .fontWeight(.bold)
                        .opacity(isSelected ? 1 : 0)
                )
        }
        .buttonStyle(.plain)
    }
}
