//
//  WordTagSelectionView.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/9/25.
//

import SwiftUI

struct WordTagSelectionView: View {
    @ObservedObject var word: CDWord
    let availableTags: [CDTag]
    @Environment(\.dismiss) private var dismiss
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    
    private let tagService = ServiceManager.shared.tagService
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    ForEach(availableTags, id: \.id) { tag in
                        TagSelectionRow(
                            tag: tag,
                            isSelected: word.tagsArray.contains { $0.id == tag.id }
                        ) {
                            toggleTag(tag)
                        }
                    }
                } header: {
                    Text("Select Tags")
                } footer: {
                    Text("You can select up to 5 tags per word. Tap a tag to select or deselect it.")
                }
            }
            .navigationTitle("Manage Tags")
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
            .alert("Error", isPresented: $showingErrorAlert) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func toggleTag(_ tag: CDTag) {
        do {
            if word.tagsArray.contains(where: { $0.id == tag.id }) {
                try tagService.removeTagFromWord(tag, word: word)
                AnalyticsService.shared.logEvent(.tagRemovedFromWord)
            } else {
                try tagService.addTagToWord(tag, word: word)
                AnalyticsService.shared.logEvent(.tagAddedToWord)
            }
        } catch {
            handleError(error)
        }
    }
    
    private func handleError(_ error: Error) {
        if let coreError = error as? CoreError {
            errorMessage = coreError.description
        } else {
            errorMessage = error.localizedDescription
        }
        showingErrorAlert = true
    }
}

#Preview {
    WordTagSelectionView(
        word: CDWord(),
        availableTags: []
    )
} 