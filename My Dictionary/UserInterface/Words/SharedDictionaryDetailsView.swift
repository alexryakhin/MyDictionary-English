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
        _dictionary = .init(initialValue: dictionary)
    }

    var body: some View {
        ScrollView {
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
                    ListWithDivider(dictionary.collaborators.keys.sorted()) { userId in
                        let role = dictionary.collaborators[userId]
                        HStack {
                            VStack(alignment: .leading) {
                                Text(role?.displayValue ?? "Unknown")
                                    .font(.headline)
                                Text(userId)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            if dictionary.canEdit && userId != authenticationService.userId && role != .owner {
                                Menu {
                                    switch role {
                                    case .editor:
                                        Button("Make Viewer") {
                                            updateRole(userId: userId, role: .viewer)
                                        }
                                    case .viewer:
                                        Button("Make Editor") {
                                            updateRole(userId: userId, role: .editor)
                                        }
                                    default:
                                        EmptyView()
                                    }

                                    Button("Remove", role: .destructive) {
                                        removeCollaborator(userId: userId)
                                    }
                                } label: {
                                    Image(systemName: "ellipsis.circle")
                                        .foregroundStyle(.secondary)
                                }
                            } else if userId == authenticationService.userId {
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
                        HeaderButton(text: "Add", icon: "plus", style: .borderedProminent) {
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
                                    deleteDictionary()
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
                } else if let userId = authenticationService.userId{
                    Button {
                        AlertCenter.shared.showAlert(
                            with: .deleteConfirmation(
                                title: "Stop watching dictionary",
                                message: "Are you sure you want to stop watching this shared dictionary?",
                                deleteText: "Continue",
                                onDelete: {
                                    removeCollaborator(userId: userId)
                                    dismiss()
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
        }
        .groupedBackground()
        .navigation(
            title: "Dictionary Details",
            mode: .inline,
            showsBackButton: true
        )
        .sheet(isPresented: $showingAddCollaborator) {
            AddCollaboratorView(dictionaryId: dictionary.id)
        }
        .onChange(of: dictionaryService.sharedDictionaries) { newValue in
            if let dictionary = newValue.first(where: { $0.id == self.dictionary.id }) {
                self.dictionary = dictionary
                if !dictionary.canView {
                    TabManager.shared.popToRootPublisher.send()
                }
            } else {
                TabManager.shared.popToRootPublisher.send()
            }
        }
    }
    
    private func updateRole(userId: String, role: CollaboratorRole) {
        Task {
            do {
                try await dictionaryService.updateCollaboratorRole(
                    dictionaryId: dictionary.id,
                    userId: userId,
                    role: role
                )
            } catch {
                errorReceived(error)
            }
        }
    }
    
    private func removeCollaborator(userId: String) {
        Task {
            do {
                try await dictionaryService.removeCollaborator(
                    dictionaryId: dictionary.id,
                    userId: userId
                )
            } catch {
                errorReceived(error)
            }
        }
    }
    
    private func deleteDictionary() {
        Task {
            do {
                try await dictionaryService.deleteSharedDictionary(
                    dictionaryId: dictionary.id
                )
                TabManager.shared.popToRootPublisher.send()
            } catch {
                errorReceived(error)
            }
        }
    }
}
