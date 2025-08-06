//
//  SharedDictionaryDetailsView.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import SwiftUI

struct SharedDictionaryDetailsView: View {
    @StateObject var dictionaryService: DictionaryService = .shared
    @StateObject var authenticationService: AuthenticationService = .shared
    let dictionary: DictionaryService.SharedDictionary
    @State private var showingAddCollaborator = false
    @State private var showingDeleteAlert = false
    @State private var errorMessage: String?
    @Environment(\.dismiss) var dismiss
    
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
                    Text(dictionary.userRole?.capitalized ?? "Unknown")
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
                            Text(userId == dictionary.owner ? "Owner" : dictionary.collaborators[userId]?.capitalized ?? "Unknown")
                                .font(.headline)
                            Text(userId)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        if dictionary.canEdit && userId != authenticationService.userId {
                            Menu {
                                if dictionary.collaborators[userId] == "viewer" {
                                    Button("Make Editor") {
                                        updateRole(userId: userId, role: "editor")
                                    }
                                } else {
                                    Button("Make Viewer") {
                                        updateRole(userId: userId, role: "viewer")
                                    }
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
                        showingDeleteAlert = true
                    }
                }
            }

            if let errorMessage = errorMessage {
                Section {
                    Text(errorMessage)
                        .foregroundColor(.red)
                }
            }
        }
        .navigationTitle("Dictionary Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Done") {
                    dismiss()
                }
            }
        }
        .sheet(isPresented: $showingAddCollaborator) {
            AddCollaboratorView(dictionaryId: dictionary.id)
        }
        .alert("Delete Dictionary", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteDictionary()
            }
        } message: {
            Text("Are you sure you want to delete this shared dictionary? This action cannot be undone.")
        }
    }
    
    private func updateRole(userId: String, role: String) {
        dictionaryService.updateCollaboratorRole(dictionaryId: dictionary.id, userId: userId, role: role) { result in
            switch result {
            case .success:
                errorMessage = nil
            case .failure(let error):
                errorMessage = error.localizedDescription
            }
        }
    }
    
    private func removeCollaborator(userId: String) {
        dictionaryService.removeCollaborator(dictionaryId: dictionary.id, userId: userId) { result in
            switch result {
            case .success:
                errorMessage = nil
            case .failure(let error):
                errorMessage = error.localizedDescription
            }
        }
    }
    
    private func deleteDictionary() {
        dictionaryService.deleteSharedDictionary(dictionaryId: dictionary.id) { result in
            switch result {
            case .success:
                dismiss()
            case .failure(let error):
                errorMessage = error.localizedDescription
            }
        }
    }
}
