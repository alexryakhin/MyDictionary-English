//
//  AddCollaboratorView.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import SwiftUI

struct AddCollaboratorView: View {
    @StateObject var dictionaryService: DictionaryService = .shared
    let dictionaryId: String
    @State private var email = ""
    @State private var role = "editor"
    @State private var errorMessage: String?
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Collaborator Details")) {
                    TextField("Email Address", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()

                    Picker("Role", selection: $role) {
                        Text("Editor").tag("editor")
                        Text("Viewer").tag("viewer")
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section(header: Text("Role Permissions")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Editor:")
                            .font(.headline)
                        Text("• Can add, edit, and delete words")
                        Text("• Can invite other collaborators")
                        Text("• Can manage dictionary settings")
                    }
                    .foregroundColor(.secondary)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Viewer:")
                            .font(.headline)
                        Text("• Can view all words")
                        Text("• Cannot make changes")
                        Text("• Cannot invite others")
                    }
                    .foregroundColor(.secondary)
                }
                
                if let errorMessage = errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                    }
                }
                
                Section {
                    Button("Add Collaborator") {
                        addCollaborator()
                    }
                    .disabled(email.isEmpty || dictionaryService.isLoading)
                }
            }
            .navigationTitle("Add Collaborator")
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
                    ProgressView("Adding...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.3))
                }
            }
        }
    }
    
    private func addCollaborator() {
        guard !email.isEmpty else {
            errorMessage = "Email address is required"
            return
        }
        
        guard email.contains("@") else {
            errorMessage = "Please enter a valid email address"
            return
        }
        
        dictionaryService.addCollaborator(dictionaryId: dictionaryId, email: email.trimmingCharacters(in: .whitespacesAndNewlines), role: role) { result in
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
