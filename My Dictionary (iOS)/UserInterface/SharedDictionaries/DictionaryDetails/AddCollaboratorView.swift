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
    @StateObject var authenticationService = AuthenticationService.shared
    @State private var searchQuery = ""
    @State private var role: CollaboratorRole = .editor
    @State private var isLoading = false
    @State private var isSearching = false
    @State private var foundUser: UserInfo?
    @State private var searchError: String?
    @State private var searchMode: SearchMode = .email

    let dictionaryId: String
    
    enum SearchMode: String, CaseIterable {
        case email = "Email"
        case nickname = "Nickname"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Search Mode Selection
                CustomSectionView(header: Loc.Auth.searchMethod.localized) {
                    Picker("Search by", selection: $searchMode) {
                        ForEach(SearchMode.allCases, id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal, 16)
                }
                
                // Search Section
                CustomSectionView(header: searchMode == .email ? Loc.Auth.findUserByEmail.localized : Loc.Auth.findUserByNickname.localized) {
                    VStack(spacing: 12) {
                        HStack {
                            TextField(
                                searchMode == .email ? Loc.Auth.enterEmailAddress.localized : Loc.Auth.enterNickname.localized,
                                text: $searchQuery
                            )
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                            .padding(vertical: 8, horizontal: 12)
                            .background(Color.tertiarySystemGroupedBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            #if os(iOS)
                            .keyboardType(searchMode == .email ? .emailAddress : .default)
                            #endif
                            
                            Button {
                                Task {
                                    await searchUser()
                                }
                            } label: {
                                if isSearching {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "magnifyingglass")
                                        .foregroundStyle(.blue)
                                }
                            }
                            .disabled(searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSearching)
                        }
                        
                        if let error = searchError {
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }
                }
                
                // Found User Section
                if let foundUser = foundUser {
                    CustomSectionView(header: Loc.Auth.foundUser.localized) {
                        VStack(spacing: 12) {
                            HStack {
                                Image(systemName: "person.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(.accent)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(foundUser.displayName ?? "Unknown User")
                                        .font(.body)
                                        .fontWeight(.medium)
                                    
                                    Text(foundUser.email)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    
                                    if let nickname = foundUser.nickname {
                                        Text("@\(nickname)")
                                            .font(.caption)
                                            .foregroundStyle(.blue)
                                    }
                                }
                                
                                Spacer()
                                
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                            }
                            .padding(vertical: 12, horizontal: 16)
                            .clippedWithBackground(Color.tertiarySystemGroupedBackground, cornerRadius: 16)
                        }
                    }
                }

                // Role Selection
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
                
                // Note Section
                CustomSectionView(header: Loc.App.note.localized, hPadding: .zero) {
                    VStack(alignment: .leading, spacing: 8) {
                        if searchMode == .email {
                            Text(Loc.SharedDictionaries.collaboratorAddedWithEmailName.localized)
                        } else {
                            Text("The user will be added to the shared dictionary. They will receive a notification and can access the dictionary immediately.")
                        }
                    }
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(vertical: 12, horizontal: 16)
                }
            }
            .padding(.horizontal, 16)
            .if(isPad) { view in
                view
                    .frame(maxWidth: 550, alignment: .center)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
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
            AsyncActionButton(
                Loc.CollaboratorManagement.addCollaborator.localized,
                style: .borderedProminent
            ) {
                try await addCollaborator()
            }
            .disabled(foundUser == nil)
            .padding(vertical: 12, horizontal: 16)
        }
    }

    private func addCollaborator() async throws {
        guard let foundUser = foundUser else {
            showAlertWithMessage(Loc.Auth.userNotFound.localized)
            return
        }

        guard !foundUser.email.isEmpty else {
            showAlertWithMessage(Loc.CollaboratorManagement.emailAddressRequired.localized)
            return
        }

        guard foundUser.email.contains("@") else {
            showAlertWithMessage(Loc.CollaboratorManagement.validEmailAddress.localized)
            return
        }

        try await dictionaryService.addCollaborator(
            dictionaryId: dictionaryId,
            userId: foundUser.id,
            email: foundUser.email.trimmingCharacters(in: .whitespacesAndNewlines),
            displayName: foundUser.displayName,
            role: role
        )
        dismiss()
    }

    private func searchUser() async {
        isSearching = true
        searchError = nil
        foundUser = nil

        let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)

        if query.isEmpty {
            isSearching = false
            return
        }

        do {
            if searchMode == .email {
                foundUser = try await authenticationService.searchUserByEmail(query)
            } else {
                foundUser = try await authenticationService.searchUserByNickname(query)
            }
        } catch {
            searchError = error.localizedDescription
        }
        isSearching = false
    }
}
