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
                return Loc.Profile.email
            case .nickname:
                return Loc.Profile.nickname
            }
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Search Mode Selection
                CustomSectionView(header: Loc.Profile.searchMethod) {
                    Picker(Loc.Profile.searchBy, selection: $searchMode) {
                        ForEach(SearchMode.allCases, id: \.self) { mode in
                            Text(mode.localizedName).tag(mode)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                // Search Section
                CustomSectionView(header: searchMode == .email ? Loc.Profile.findUserByEmail : Loc.Profile.findUserByNickname) {
                    VStack(spacing: 12) {
                        HStack {
                            TextField(
                                searchMode == .email ? Loc.Profile.enterEmailAddress : Loc.Profile.enterNickname,
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
                    CustomSectionView(header: Loc.Profile.foundUser) {
                        VStack(spacing: 12) {
                            HStack {
                                Image(systemName: "person.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(.accent)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(foundUser.displayName ?? Loc.Profile.unknownUser)
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
                            .clippedWithBackground(Color.tertiarySystemGroupedBackground, in: .rect(cornerRadius: 16))
                        }
                    }
                }

                // Role Selection
                CustomSectionView(header: Loc.SharedDictionaries.rolePermissions, hPadding: .zero) {
                    FormWithDivider {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(Loc.SharedDictionaries.editorRole)
                                .font(.headline)
                            Text(Loc.SharedDictionaries.canAddEditDeleteWords)
                            Text(Loc.SharedDictionaries.canInviteCollaborators)
                            Text(Loc.SharedDictionaries.canManageDictionarySettings)
                        }
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(vertical: 12, horizontal: 16)

                        VStack(alignment: .leading, spacing: 8) {
                            Text(Loc.SharedDictionaries.viewer)
                                .font(.headline)
                            Text(Loc.SharedDictionaries.canViewAllWords)
                            Text(Loc.SharedDictionaries.cannotMakeChanges)
                            Text(Loc.SharedDictionaries.cannotInviteOthers)
                        }
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(vertical: 12, horizontal: 16)
                    }
                }
                
                // Note Section
                CustomSectionView(header: Loc.SharedDictionaries.note, hPadding: .zero) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(Loc.SharedDictionaries.collaboratorAddedWithEmailName)
                    }
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(vertical: 12, horizontal: 16)
                }
            }
            .padding(vertical: 12, horizontal: 16)
            .if(isPad) { view in
                view
                    .frame(maxWidth: 550, alignment: .center)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .groupedBackground()
        .navigation(
            title: Loc.SharedDictionaries.CollaboratorManagement.addCollaborator,
            mode: .inline,
            trailingContent: {
                HeaderButton(icon: "xmark") {
                    dismiss()
                }
            }
        )
        .safeAreaBarIfAvailable {
            AsyncActionButton(
                Loc.SharedDictionaries.CollaboratorManagement.addCollaborator,
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
            showAlertWithMessage(Loc.Profile.userNotFound)
            return
        }

        guard !foundUser.email.isEmpty else {
            showAlertWithMessage(Loc.SharedDictionaries.CollaboratorManagement.emailAddressRequired)
            return
        }

        guard foundUser.email.contains("@") else {
            showAlertWithMessage(Loc.SharedDictionaries.CollaboratorManagement.validEmailAddress)
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
