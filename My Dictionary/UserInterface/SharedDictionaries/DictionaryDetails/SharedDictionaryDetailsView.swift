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

    let dictionaryId: String
    
    // Computed property to get the current dictionary from the service
    private var dictionary: SharedDictionary? {
        let dict = dictionaryService.sharedDictionaries.first { $0.id == dictionaryId }
        print("🔍 [SharedDictionaryDetailsView] Looking for dictionary with ID: \(dictionaryId)")
        print("🔍 [SharedDictionaryDetailsView] Available dictionaries: \(dictionaryService.sharedDictionaries.map { $0.id }.joined(separator: ", "))")
        print("🔍 [SharedDictionaryDetailsView] Found dictionary: \(dict?.name ?? "nil")")
        return dict
    }

    init(dictionary: SharedDictionary) {
        self.dictionaryId = dictionary.id
    }
    
    var body: some View {
        ScrollView {
            if let dictionary = dictionary {
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
                            HeaderButton("Add", icon: "plus", style: .borderedProminent) {
                                showingAddCollaborator = true
                            }
                        }
                    }

                    if dictionary.isOwner {
                        Button {
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
                        } label: {
                            Text("Delete Dictionary")
                                .padding(.vertical, 8)
                                .frame(maxWidth: .infinity)
                        }
                        .tint(.red)
                        .buttonStyle(.bordered)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    } else if let userEmail = authenticationService.userEmail {
                        Button {
                            AlertCenter.shared.showAlert(
                                with: .deleteConfirmation(
                                    title: "Stop watching dictionary",
                                    message: "Are you sure you want to stop watching this shared dictionary?",
                                    deleteText: "Continue",
                                    onDelete: {
                                        Task {
                                            await removeCollaborator(email: userEmail)
                                            dismiss()
                                        }
                                    }
                                )
                            )
                        } label: {
                            Text("Stop watching")
                                .padding(.vertical, 8)
                                .frame(maxWidth: .infinity)
                        }
                        .tint(.red)
                        .buttonStyle(.bordered)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                }
                .padding(.horizontal, 16)
            } else {
                // Dictionary not found or user lost access
                VStack(spacing: 16) {
                    ContentUnavailableView(
                        "Dictionary Not Found",
                        systemImage: "exclamationmark.triangle",
                        description: Text("This dictionary may have been deleted or you may have lost access to it.")
                    )
                }
                .padding(.horizontal, 16)
            }
        }
        .groupedBackground()
        .navigation(
            title: "Dictionary Details",
            mode: .inline,
            showsBackButton: true
        )
        .sheet(isPresented: $showingAddCollaborator) {
            AddCollaboratorView(dictionaryId: dictionaryId)
        }
        .refreshable {
            await refreshDictionaryDetails()
        }
        .onChange(of: dictionaryService.sharedDictionaries) { newValue in
            print("🔄 [SharedDictionaryDetailsView] sharedDictionaries changed, count: \(newValue.count)")
            print("🔄 [SharedDictionaryDetailsView] Current dictionaryId: \(dictionaryId)")
            print("🔄 [SharedDictionaryDetailsView] Available dictionaries: \(newValue.map { $0.id }.joined(separator: ", "))")
            
            // Check if user lost access to this dictionary
            if !newValue.contains(where: { $0.id == dictionaryId }) {
                print("🚫 [SharedDictionaryDetailsView] Dictionary no longer accessible, popping to root")
                NavigationManager.shared.popToRoot()
            }
        }
    }

    private func updateRole(email: String, role: CollaboratorRole) {
        Task {
            do {
                try await dictionaryService.updateCollaboratorRole(
                    dictionaryId: dictionaryId,
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
                    dictionaryId: dictionaryId,
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
                print("🗑️ [SharedDictionaryDetailsView] Starting dictionary deletion")
                try await dictionaryService.deleteSharedDictionary(
                    dictionaryId: dictionaryId
                )
                print("✅ [SharedDictionaryDetailsView] Dictionary deleted successfully, popping to root")
                NavigationManager.shared.popToRoot()
            } catch {
                print("❌ [SharedDictionaryDetailsView] Error deleting dictionary: \(error.localizedDescription)")
                errorReceived(error)
            }
        }
    }
    
    private func refreshDictionaryDetails() async {
        print("🔄 [SharedDictionaryDetailsView] Pull-to-refresh triggered for dictionary: \(dictionaryId)")
        
        // Force a refresh of the shared dictionaries
        dictionaryService.refreshSharedDictionaries()
        
        // Add a small delay to ensure the refresh completes
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        print("✅ [SharedDictionaryDetailsView] Pull-to-refresh completed for dictionary: \(dictionaryId)")
    }
}
