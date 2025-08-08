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
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Dictionary Details")) {
                    TextField("Dictionary Name", text: $name)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }

                Section {
                    Button("Create Shared Dictionary") {
                        createDictionary()
                    }
                    .disabled(name.isEmpty)
                }
            }
            .navigationTitle("New Shared Dictionary")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
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
        Task {
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
