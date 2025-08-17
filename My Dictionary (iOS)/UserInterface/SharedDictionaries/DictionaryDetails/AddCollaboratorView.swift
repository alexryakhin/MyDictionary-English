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
                CustomSectionView(header: Loc.App.collaboratorDetails.localized) {
                    VStack(spacing: 12) {
                        TextField(Loc.App.emailAddress.localized, text: $email)
                            .autocorrectionDisabled()
                            .padding(vertical: 8, horizontal: 12)
                            .background(Color.tertiarySystemGroupedBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            #if os(iOS)
                            .keyboardType(.emailAddress)
                            #endif

                        TextField(Loc.App.name.localized, text: $name)
                            .autocorrectionDisabled()
                            .padding(vertical: 8, horizontal: 12)
                            .background(Color.tertiarySystemGroupedBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            #if os(iOS)
                            .keyboardType(.emailAddress)
                            #endif

                        Picker(Loc.CollaboratorManagement.role.localized, selection: $role) {
                            ForEach(CollaboratorRole.allCases, id: \.self) { role in
                                Text(role.displayValue)
                                    .tag(role.rawValue)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                }

                CustomSectionView(header: Loc.App.rolePermissions.localized, hPadding: .zero) {
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
                
                CustomSectionView(header: Loc.App.note.localized, hPadding: .zero) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(Loc.SharedDictionaries.collaboratorAddedWithEmailName.localized)
                    }
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(vertical: 12, horizontal: 16)
                }
            }
            .padding(.horizontal, 16)
        }
        .groupedBackground()
        .navigation(
            title: Loc.CollaboratorManagement.addCollaborator.localized,
            mode: .inline,
            trailingContent: {
                HeaderButton(icon: "xmark") {
                    dismiss()
                }
            }
        )
        .safeAreaInset(edge: .bottom) {
            ActionButton(
                Loc.CollaboratorManagement.addCollaborator.localized,
                style: .borderedProminent,
                isLoading: isLoading
            ) {
                addCollaborator()
            }
            .disabled(email.isEmpty && name.isEmpty)
            .padding(vertical: 12, horizontal: 16)
        }
    }

    private func addCollaborator() {
        guard !email.isEmpty else {
            showAlertWithMessage(Loc.CollaboratorManagement.emailAddressRequired.localized)
            return
        }

        guard email.contains("@") else {
            showAlertWithMessage(Loc.CollaboratorManagement.validEmailAddress.localized)
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
