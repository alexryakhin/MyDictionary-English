//
//  AddCollaboratorView.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import SwiftUI

struct AddCollaboratorView: View {
    @Environment(\.dismiss) var dismiss

    @StateObject var dictionaryService: DictionaryService = .shared
    @State private var email = ""
    @State private var name = ""
    @State private var role: CollaboratorRole = .editor
    @State private var isLoading = false

    let dictionaryId: String

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                CustomSectionView(header: "Collaborator Details") {
                    VStack(spacing: 12) {
                        TextField("Email Address", text: $email)
                            .textFieldStyle(.plain)
                            .autocorrectionDisabled()
                            .padding(vertical: 8, horizontal: 12)
                            .background(Color.tertiarySystemGroupedBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                        TextField("Name", text: $name)
                            .textFieldStyle(.plain)
                            .autocorrectionDisabled()
                            .padding(vertical: 8, horizontal: 12)
                            .background(Color.tertiarySystemGroupedBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                        Picker("Role", selection: $role) {
                            ForEach(CollaboratorRole.allCases, id: \.self) { role in
                                Text(role.displayValue)
                                    .tag(role.rawValue)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                }

                CustomSectionView(header: "Role Permissions", hPadding: .zero) {
                    FormWithDivider {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Editor:")
                                .font(.headline)
                            Text("• Can add, edit, and delete words")
                            Text("• Can invite other collaborators")
                            Text("• Can manage dictionary settings")
                        }
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(vertical: 12, horizontal: 16)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Viewer:")
                                .font(.headline)
                            Text("• Can view all words")
                            Text("• Cannot make changes")
                            Text("• Cannot invite others")
                        }
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(vertical: 12, horizontal: 16)
                    }
                }
                
                CustomSectionView(header: "Note", hPadding: .zero) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("The collaborator will be added with the email and name you provide. They will need to sign in with the same email address to access the shared dictionary.")
                    }
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(vertical: 12, horizontal: 16)
                }
            }
            .padding(12)
        }
        .groupedBackground()
        .navigationTitle("Add Collaborator")
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                // Close button
                Button("Close") {
                    dismiss()
                }
                .help("Close Add Collaborator")
                
                // Add collaborator button
                Button("Add Collaborator") {
                    addCollaborator()
                }
                .buttonStyle(.borderedProminent)
                .disabled(email.isEmpty && name.isEmpty)
                .help("Add Collaborator")
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

        Task { @MainActor in
            isLoading = true
            defer {
                isLoading = false
            }
            do {
                try await dictionaryService.addCollaborator(
                    dictionaryId: dictionaryId,
                    userId: email.lowercased().replacingOccurrences(of: "@", with: "_").replacingOccurrences(of: ".", with: "_"),
                    email: email.trimmingCharacters(in: .whitespacesAndNewlines),
                    displayName: name.isEmpty ? nil : name,
                    role: role
                )
                dismiss()
            } catch {
                errorReceived(error)
            }
        }
    }
}
