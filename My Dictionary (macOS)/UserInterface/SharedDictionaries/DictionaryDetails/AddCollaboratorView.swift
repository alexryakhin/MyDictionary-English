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
        
        var localizedName: String {
            switch self {
            case .email:
                return Loc.Auth.email.localized
            case .nickname:
                return Loc.Auth.nickname.localized
            }
        }
    }

    var body: some View {
        ScrollViewWithCustomNavBar {
            VStack(spacing: 16) {
                // Search Mode Selection
                CustomSectionView(header: Loc.Auth.searchMethod.localized) {
                    Picker(Loc.Auth.searchBy.localized, selection: $searchMode) {
                        ForEach(SearchMode.allCases, id: \.self) { mode in
                            Text(mode.localizedName).tag(mode)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
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
                            .padding(vertical: 8, horizontal: 12)
                            .background(Color.tertiarySystemGroupedBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            
                            Button {
                                Task {
                                    await searchUser()
                                }
                            } label: {
                                if isSearching {
                                    LoaderView()
                                        .frame(width: 24, height: 24)
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
                                    Text(foundUser.displayName ?? Loc.Auth.unknownUser.localized)
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
                title: Loc.CollaboratorManagement.addCollaborator.localized,
                trailingContent: {
                    AsyncHeaderButton(
                        Loc.CollaboratorManagement.addCollaborator.localized,
                        style: .borderedProminent
                    ) {
                        try await addCollaborator()
                    }
                    .disabled(foundUser == nil)
                    .help(Loc.CollaboratorManagement.addCollaborator.localized)
                }
            )
        }
        .groupedBackground()
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
