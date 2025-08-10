//
//  SharedDictionarySelectionView.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import SwiftUI

struct SharedDictionarySelectionView: View {
    @StateObject private var dictionaryService = DictionaryService.shared
    @State private var selectedDictionaryId: String? = nil
    @State private var showingAddDictionary = false
    @Environment(\.dismiss) private var dismiss
    
    let onDictionarySelected: (String?) -> Void
    
    var body: some View {
        List {
            Section {
                Button {
                    selectedDictionaryId = nil
                    onDictionarySelected(nil)
                    dismiss()
                } label: {
                    HStack {
                        Image(systemName: "person")
                            .foregroundStyle(.blue)
                            .frame(width: 24)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Private Dictionary")
                                .font(.headline)

                            Text("Save to your personal dictionary")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        if selectedDictionaryId == nil {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.blue)
                        }
                    }
                }
                .buttonStyle(.plain)
            } header: {
                Text("Private")
            }

            if !dictionaryService.sharedDictionaries.isEmpty {
                Section {
                    ForEach(dictionaryService.sharedDictionaries) { dictionary in
                        Button {
                            selectedDictionaryId = dictionary.id
                            onDictionarySelected(dictionary.id)
                            dismiss()
                        } label: {
                            HStack {
                                Image(systemName: "person.2")
                                    .foregroundStyle(.green)
                                    .frame(width: 24)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(dictionary.name)
                                        .font(.headline)

                                    HStack {
                                        Text("\(dictionary.collaborators.count) collaborators")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)

                                        if dictionary.isOwner {
                                            Text("Owner")
                                                .font(.caption)
                                                .foregroundStyle(.green)
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(Color.green.opacity(0.2))
                                                .cornerRadius(4)
                                        }
                                    }
                                }

                                Spacer()

                                if selectedDictionaryId == dictionary.id {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    Text("Shared Dictionaries")
                }
            }

            if dictionaryService.sharedDictionaries.isEmpty {
                Section {
                    Button {
                        showingAddDictionary = true
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle")
                                .foregroundStyle(.blue)
                            Text("Create Shared Dictionary")
                                .foregroundStyle(.blue)
                        }
                    }
                } header: {
                    Text("Shared Dictionaries")
                } footer: {
                    Text("Create a shared dictionary to collaborate with others")
                }
            }
        }
        .navigationTitle("Select Dictionary")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
            }
        }
        .sheet(isPresented: $showingAddDictionary) {
            AddSharedDictionaryView()
        }
        .onAppear {
            dictionaryService.setupSharedDictionariesListener()
        }
    }
} 
