//
//  SharedDictionarySelectionView.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import SwiftUI

struct SharedDictionarySelectionView: View {
    @Environment(\.dismiss) private var dismiss

    @StateObject private var subscriptionService = SubscriptionService.shared
    @StateObject private var dictionaryService = DictionaryService.shared
    @State private var selectedDictionaryId: String? = nil
    @State private var showingAddDictionary = false
    private let onDictionarySelected: StringOptionalHandler

    init(
        selectedDictionaryId: String? = nil,
        onDictionarySelected: @escaping StringOptionalHandler
    ) {
        self._selectedDictionaryId = .init(initialValue: selectedDictionaryId)
        self.onDictionarySelected = onDictionarySelected
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                CustomSectionView(header: "Private", hPadding: .zero) {
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
                        .padding(vertical: 12, horizontal: 16)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }

                if !dictionaryService.sharedDictionaries.isEmpty {
                    CustomSectionView(header: "Shared Dictionaries", hPadding: .zero) {
                        ListWithDivider(dictionaryService.sharedDictionaries) { dictionary in
                            Button {
                                selectedDictionaryId = dictionary.id
                                onDictionarySelected(dictionary.id)
                                dismiss()
                            } label: {
                                HStack {
                                    Image(systemName: "person.2")
                                        .foregroundStyle(.accent)
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
                                                    .foregroundStyle(.accent)
                                                    .padding(.horizontal, 6)
                                                    .padding(.vertical, 2)
                                                    .background(Color.accent.opacity(0.2))
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
                                .padding(vertical: 12, horizontal: 16)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                } else {
                    CustomSectionView(
                        header: "Shared Dictionaries",
                        footer: "Create a shared dictionary to collaborate with others"
                    ) {
                        ActionButton(
                            "Create Shared Dictionary",
                            systemImage: "plus.circle"
                        ) {
                            showingAddDictionary = true
                        }
                        .padding(.bottom, 12)
                    }
                }
            }
            .padding(12)
        }
        .groupedBackground()
        .navigationTitle("Select Dictionary")
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                // Close button
                Button("Close") {
                    dismiss()
                }
                .help("Close Dictionary Selection")
            }
        }
        .sheet(isPresented: $showingAddDictionary) {
            if dictionaryService.canCreateMoreSharedDictionaries() {
                AddSharedDictionaryView()
                    .presentationCornerRadius(24)
            } else {
                MyPaywallView()
            }
        }
        .onAppear {
            dictionaryService.setupSharedDictionariesListener()
        }
    }
} 
