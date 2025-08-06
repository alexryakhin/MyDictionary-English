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
    @State private var errorMessage: String?
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Dictionary Details")) {
                    TextField("Dictionary Name", text: $name)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                if let errorMessage = errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                    }
                }
                
                Section {
                    Button("Create Shared Dictionary") {
                        createDictionary()
                    }
                    .disabled(name.isEmpty || dictionaryService.isLoading)
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
            .overlay {
                if dictionaryService.isLoading {
                    ProgressView("Creating...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.3))
                }
            }
        }
    }
    
    private func createDictionary() {
        guard !name.isEmpty else {
            errorMessage = "Dictionary name is required"
            return
        }
        
        guard let userId = authenticationService.userId else {
            errorMessage = "Please sign in to create a shared dictionary"
            return
        }
        
        dictionaryService.createSharedDictionary(userId: userId, name: name.trimmingCharacters(in: .whitespacesAndNewlines)) { result in
            switch result {
            case .success:
                errorMessage = nil
                dismiss()
            case .failure(let error):
                errorMessage = error.localizedDescription
            }
        }
    }
}
