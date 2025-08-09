//
//  SharedDictionariesListView.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import SwiftUI

struct SharedDictionariesListView: View {
    @StateObject private var dictionaryService = DictionaryService.shared
    @State private var showingAddDictionary = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        List {
            if dictionaryService.sharedDictionaries.isEmpty {
                ContentUnavailableView(
                    "No Shared Dictionaries",
                    systemImage: "person.2",
                    description: Text("Create a shared dictionary to collaborate with others")
                )
            } else {
                ForEach(dictionaryService.sharedDictionaries) { dictionary in
                    NavigationLink {
                        SharedDictionaryDetailsView(dictionary: dictionary)
                    } label: {
                        HStack {
                            Image(systemName: "person.2")
                                .foregroundColor(.blue)
                                .frame(width: 24)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(dictionary.name)
                                    .font(.headline)
                                
                                HStack {
                                    Text("\(dictionary.collaborators.count) collaborators")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    if dictionary.isOwner {
                                        Text("Owner")
                                            .font(.caption)
                                            .foregroundColor(.green)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color.green.opacity(0.2))
                                            .cornerRadius(4)
                                    }
                                }
                            }
                            
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .navigationTitle("Shared Dictionaries")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Done") {
                    dismiss()
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingAddDictionary = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddDictionary) {
            AddSharedDictionaryView()
        }
    }
} 
