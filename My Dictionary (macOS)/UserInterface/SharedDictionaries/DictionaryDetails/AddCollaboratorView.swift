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
        ScrollViewWithCustomNavBar {
            VStack(spacing: 12) {
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

                        HStack {
                            Text(Loc.SharedDictionaries.selectRole.localized)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            HeaderButtonMenu(role.displayValue, size: .small) {
                                Picker("Role", selection: $role) {
                                    ForEach(CollaboratorRole.allCases, id: \.self) { role in
                                        Text(role.displayValue)
                                            .tag(role.rawValue)
                                    }
                                }
                                .pickerStyle(.inline)
                            }
                        }
                        .padding(vertical: 8, horizontal: 12)
                        .background(Color.tertiarySystemGroupedBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }

                CustomSectionView(header: "Role Permissions", hPadding: .zero) {
                    FormWithDivider {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(Loc.SharedDictionaries.editorRole.localized)
                                .font(.headline)
                            Text(Loc.SharedDictionaries.canAddEditDeleteWords.localized)
                            Text(Loc.SharedDictionaries.canInviteCollaborators.localized)
                            Text(Loc.SharedDictionaries.canManageDictionarySettings.localized)
                        }
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(vertical: 12, horizontal: 16)

                        VStack(alignment: .leading, spacing: 8) {
                            Text(Loc.SharedDictionaries.viewer.localized)
                                .font(.headline)
                            Text(Loc.SharedDictionaries.canViewAllWords.localized)
                            Text(Loc.SharedDictionaries.cannotMakeChanges.localized)
                            Text(Loc.SharedDictionaries.cannotInviteOthers.localized)
                        }
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(vertical: 12, horizontal: 16)
                    }
                }

                CustomSectionView(header: "Note", hPadding: .zero) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(Loc.SharedDictionaries.collaboratorAddedWithEmailName.localized)
                    }
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(vertical: 12, horizontal: 16)
                }
            }
            .padding(12)
        } navigationBar: {
            NavigationBarView(
                title: "Add Collaborator",
                trailingContent: {
                    HeaderButton("Add Collaborator", style: .borderedProminent) {
                        addCollaborator()
                    }
                    .disabled(email.isEmpty && name.isEmpty)
                    .help("Add Collaborator")
                }
            )
        }
        .groupedBackground()
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
