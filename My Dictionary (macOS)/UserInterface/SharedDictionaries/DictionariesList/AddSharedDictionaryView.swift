//
//  AddSharedDictionaryView.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import SwiftUI

struct AddSharedDictionaryView: View {
    @StateObject var dictionaryService: DictionaryService = .shared
    @StateObject var authenticationService: AuthenticationService = .shared
    @State private var name = ""
    @State private var isLoading: Bool = false
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                CustomSectionView(header: "Name") {
                    TextField("Enter dictionary name", text: $name)
                        .textFieldStyle(.plain)
                        .submitLabel(.done)
                        .textContentType(.organizationName)
                        .padding(vertical: 8, horizontal: 12)
                        .background(Color.tertiarySystemGroupedBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(16)
        }
        .safeAreaInset(edge: .bottom) {
            ActionButton("Create Shared Dictionary", isLoading: isLoading) {
                createDictionary()
            }
            .padding(vertical: 12, horizontal: 16)
        }
        .groupedBackground()
        .navigationTitle("New Shared Dictionary")
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                // Close button
                Button("Close") {
                    dismiss()
                }
                .help("Close New Dictionary")
                
                // Create dictionary button
                Button("Create Shared Dictionary") {
                    createDictionary()
                }
                .buttonStyle(.borderedProminent)
                .disabled(name.isEmpty)
                .help("Create Shared Dictionary")
            }
        }
        .presentationDetents([.medium])
    }
    
    private func createDictionary() {
        guard !name.isEmpty else {
            showAlertWithMessage("Dictionary name is required")
            return
        }
        
        guard let userId = authenticationService.userId else {
            showAlertWithMessage("Please sign in to create a shared dictionary")
            return
        }
        Task { @MainActor in
            isLoading = true
            defer { isLoading = false }
            do {
                try await dictionaryService.createSharedDictionary(
                    userId: userId,
                    name: name.trimmingCharacters(in: .whitespacesAndNewlines)
                )
                dismiss()
            } catch {
                errorReceived(error)
            }
        }
    }
}
