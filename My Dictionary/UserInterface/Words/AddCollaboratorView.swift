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
    @State private var role: CollaboratorRole = .editor
    @Environment(\.dismiss) var dismiss

    var body: some View {
        Form {
            Section(header: Text("Collaborator Details")) {
                TextField("Email Address", text: $email)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()

                Picker("Role", selection: $role) {
                    ForEach(CollaboratorRole.allCases, id: \.self) { role in
                        Text(role.displayValue)
                            .tag(role.rawValue)
                    }
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

            Section {
                Button("Add Collaborator") {
                    addCollaborator()
                }
                .disabled(email.isEmpty)
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
    }

    private func addCollaborator() {
        guard !email.isEmpty else {
            showAlertWithMessage("Email address is required")
            return
        }

        guard email.contains("@") else {
            showAlertWithMessage("Please enter a valid email address")
            return
        }
        Task {
            do {
                try await dictionaryService.addCollaborator(
                    dictionaryId: dictionaryId,
                    email: email.trimmingCharacters(in: .whitespacesAndNewlines),
                    role: role
                )
                dismiss()
            } catch {
                errorReceived(error)
            }
        }
    }
}
