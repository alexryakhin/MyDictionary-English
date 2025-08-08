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

    let dictionary: DictionaryService.SharedDictionary

    var body: some View {
        List {
            Section(header: Text("Dictionary Info")) {
                HStack {
                    Text("Name")
                    Spacer()
                    Text(dictionary.name)
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("Created")
                    Spacer()
                    Text(dictionary.createdAt, style: .date)
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("Your Role")
                    Spacer()
                    Text(dictionary.userRole?.displayValue ?? "Unknown")
                        .foregroundColor(.secondary)
                }
                
                NavigationLink {
                    SharedDictionaryWordsView(dictionary: dictionary)
                } label: {
                    HStack {
                        Image(systemName: "textformat")
                            .foregroundColor(.blue)
                        Text("View Words")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Section(header: Text("Collaborators")) {
                ForEach(Array(dictionary.collaborators.keys.sorted()), id: \.self) { userId in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(dictionary.collaborators[userId]?.displayValue ?? "Unknown")
                                .font(.headline)
                            Text(userId)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        if dictionary.canEdit && userId != authenticationService.userId {
                            Menu {
                                switch dictionary.collaborators[userId] {
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
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }

                if dictionary.canEdit {
                    Button("Add Collaborator") {
                        showingAddCollaborator = true
                    }
                }
            }

            if dictionary.canEdit {
                Section {
                    Button("Delete Dictionary", role: .destructive) {
                        AlertCenter.shared.showAlert(
                            with: .deleteConfirmation(
                                title: "Delete Dictionary",
                                message: "Are you sure you want to delete this shared dictionary? This action cannot be undone.",
                                onDelete: {
                                    deleteDictionary()
                                }
                            )
                        )
                    }
                }
            }
        }
        .navigationTitle("Dictionary Details")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingAddCollaborator) {
            AddCollaboratorView(dictionaryId: dictionary.id)
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
            } catch {
                errorReceived(error)
            }
        }
    }
}
