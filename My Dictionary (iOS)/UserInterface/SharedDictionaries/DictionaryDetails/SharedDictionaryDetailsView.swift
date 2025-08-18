//
//  SharedDictionaryDetailsView.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import SwiftUI

struct SharedDictionaryDetailsView: View {

    @Environment(\.dismiss) var dismiss

    @StateObject var dictionaryService: DictionaryService = .shared
    @StateObject var authenticationService: AuthenticationService = .shared
    @State private var showingAddCollaborator = false
    @State private var dictionary: SharedDictionary

    init(dictionary: SharedDictionary) {
        self._dictionary = .init(wrappedValue: dictionary)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                CustomSectionView(header: Loc.App.dictionaryInfo.localized, hPadding: .zero) {
                    FormWithDivider {
                        HStack {
                            Text(Loc.SharedDictionaries.name.localized)
                            Spacer()
                            Text(dictionary.name)
                                .foregroundStyle(.secondary)
                        }
                        .padding(vertical: 12, horizontal: 16)

                        HStack {
                            Text(Loc.SharedDictionaries.created.localized)
                            Spacer()
                            Text(dictionary.createdAt, style: .date)
                                .foregroundStyle(.secondary)
                        }
                        .padding(vertical: 12, horizontal: 16)

                        HStack {
                            Text(Loc.SharedDictionaries.yourRole.localized)
                            Spacer()
                            Text(dictionary.userRole?.displayValue ?? Loc.CollaboratorManagement.unknown.localized)
                                .foregroundStyle(.secondary)
                        }
                        .padding(vertical: 12, horizontal: 16)
                    }
                }

                CustomSectionView(header: Loc.App.collaborators.localized, hPadding: .zero) {
                    ListWithDivider(dictionary.collaborators) { collaborator in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(collaborator.role.displayValue)
                                    .font(.headline)
                                Text(collaborator.displayNameOrEmail)
                                    .font(.subheadline)
                                    .foregroundStyle(.primary)
                                Text(collaborator.email)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            if dictionary.canEdit && collaborator.email != authenticationService.userEmail && collaborator.role != .owner {
                                Menu {
                                    switch collaborator.role {
                                    case .editor:
                                        Button(Loc.CollaboratorManagement.makeViewer.localized) {
                                            updateRole(email: collaborator.email, role: .viewer)
                                        }
                                    case .viewer:
                                        Button(Loc.CollaboratorManagement.makeEditor.localized) {
                                            updateRole(email: collaborator.email, role: .editor)
                                        }
                                    default:
                                        EmptyView()
                                    }

                                    Button(Loc.CollaboratorManagement.remove.localized, role: .destructive) {
                                        removeCollaborator(email: collaborator.email)
                                    }
                                } label: {
                                    Image(systemName: "ellipsis.circle")
                                        .foregroundStyle(.secondary)
                                }
                            } else if collaborator.email == authenticationService.userEmail {
                                Text(Loc.SharedDictionaries.me.localized)
                                    .font(.caption)
                                    .padding(vertical: 2, horizontal: 6)
                                    .background(.accent.opacity(0.1))
                                    .foregroundStyle(.accent)
                                    .clipShape(.capsule)
                            }
                        }
                        .padding(vertical: 12, horizontal: 16)
                    }
                } trailingContent: {
                    if dictionary.canEdit {
                        HeaderButton(Loc.CollaboratorManagement.add.localized, icon: "plus", size: .small, style: .borderedProminent) {
                            showingAddCollaborator = true
                        }
                    }
                }

                if dictionary.isOwner {
                    ActionButton(Loc.CollaboratorManagement.deleteDictionary.localized, color: .red) {
                        AlertCenter.shared.showAlert(
                            with: .deleteConfirmation(
                                title: Loc.CollaboratorManagement.deleteDictionary.localized,
                                message: Loc.CollaboratorManagement.deleteDictionaryConfirmation.localized,
                                onDelete: {
                                    Task {
                                        await deleteDictionary()
                                    }
                                }
                            )
                        )
                    }
                } else if let userEmail = authenticationService.userEmail {
                    ActionButton(Loc.CollaboratorManagement.stopWatching.localized, color: .red) {
                        AlertCenter.shared.showAlert(
                            with: .deleteConfirmation(
                                title: Loc.CollaboratorManagement.stopWatchingDictionary.localized,
                                message: Loc.CollaboratorManagement.stopWatchingDictionaryConfirmation.localized,
                                deleteText: Loc.CollaboratorManagement.continue.localized,
                                onDelete: {
                                    removeCollaborator(email: userEmail)
                                    dismiss()
                                }
                            )
                        )
                    }
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
            title: Loc.CollaboratorManagement.dictionaryDetails.localized,
            mode: .inline,
            showsBackButton: true
        )
        .sheet(isPresented: $showingAddCollaborator) {
            AddCollaboratorView(dictionaryId: dictionary.id)
        }
        .refreshable {
            await refreshDictionaryDetails()
        }
        .onChange(of: dictionaryService.sharedDictionaries) { newValue in
            if let index = newValue.firstIndex(where: { $0.id == dictionary.id }) {
                dictionary = newValue[index]
            } else {
                NavigationManager.shared.popToRoot()
            }
        }
    }

    private func updateRole(email: String, role: CollaboratorRole) {
        Task {
            do {
                try await dictionaryService.updateCollaboratorRole(
                    dictionaryId: dictionary.id,
                    email: email,
                    role: role
                )
            } catch {
                errorReceived(error)
            }
        }
    }

    private func removeCollaborator(email: String) {
        Task { @MainActor in
            do {
                try await dictionaryService.removeCollaborator(
                    dictionaryId: dictionary.id,
                    email: email
                )
            } catch {
                errorReceived(error)
            }
        }
    }

    private func deleteDictionary() {
        Task { @MainActor in
            do {
                try await dictionaryService.deleteSharedDictionary(
                    dictionaryId: dictionary.id
                )
                NavigationManager.shared.popToRoot()
            } catch {
                errorReceived(error)
            }
        }
    }

    private func refreshDictionaryDetails() async {
        // Force a refresh of the shared dictionaries
        dictionaryService.refreshSharedDictionaries()

        // Add a small delay to ensure the refresh completes
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
    }
}
