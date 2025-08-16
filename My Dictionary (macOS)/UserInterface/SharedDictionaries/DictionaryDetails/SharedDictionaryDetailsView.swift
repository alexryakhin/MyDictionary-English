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
        self._dictionary = .init(initialValue: dictionary)
    }

    var body: some View {
        ScrollViewWithCustomNavBar {
            VStack(spacing: 16) {
                CustomSectionView(header: "Dictionary Info", hPadding: .zero) {
                    FormWithDivider {
                        HStack {
                            Text("Name")
                            Spacer()
                            Text(dictionary.name)
                                .foregroundStyle(.secondary)
                        }
                        .padding(vertical: 12, horizontal: 16)

                        HStack {
                            Text("Created")
                            Spacer()
                            Text(dictionary.createdAt, style: .date)
                                .foregroundStyle(.secondary)
                        }
                        .padding(vertical: 12, horizontal: 16)

                        HStack {
                            Text("Your Role")
                            Spacer()
                            Text(dictionary.userRole?.displayValue ?? "Unknown")
                                .foregroundStyle(.secondary)
                        }
                        .padding(vertical: 12, horizontal: 16)
                    }
                }

                CustomSectionView(header: "Collaborators", hPadding: .zero) {
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
                                        Button("Make Viewer") {
                                            updateRole(email: collaborator.email, role: .viewer)
                                        }
                                    case .viewer:
                                        Button("Make Editor") {
                                            updateRole(email: collaborator.email, role: .editor)
                                        }
                                    default:
                                        EmptyView()
                                    }

                                    Button("Remove", role: .destructive) {
                                        removeCollaborator(email: collaborator.email)
                                    }
                                } label: {
                                    Image(systemName: "ellipsis.circle")
                                        .foregroundStyle(.secondary)
                                }
                                .buttonStyle(.plain)
                            } else if collaborator.email == authenticationService.userEmail {
                                Text("Me")
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
                        HeaderButton("Add", icon: "plus", size: .small, style: .borderedProminent) {
                            showingAddCollaborator = true
                        }
                    }
                }

                if dictionary.isOwner {
                    ActionButton("Delete Dictionary", color: .red) {
                        AlertCenter.shared.showAlert(
                            with: .deleteConfirmation(
                                title: "Delete Dictionary",
                                message: "Are you sure you want to delete this shared dictionary? This action cannot be undone.",
                                onDelete: {
                                    Task {
                                        await deleteDictionary()
                                    }
                                }
                            )
                        )
                    }
                } else if let userEmail = authenticationService.userEmail {
                    ActionButton("Stop watching", color: .red) {
                        AlertCenter.shared.showAlert(
                            with: .deleteConfirmation(
                                title: "Stop watching dictionary",
                                message: "Are you sure you want to stop watching this shared dictionary?",
                                deleteText: "Continue",
                                onDelete: {
                                    removeCollaborator(email: userEmail)
                                    dismiss()
                                }
                            )
                        )
                    }
                }
            }
            .padding(12)
        } navigationBar: {
            NavigationBarView(title: "Dictionary Details")
        }
        .groupedBackground()
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
                dismiss()
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
                dismiss()
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
