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
        ScrollViewWithCustomNavBar {
            VStack(spacing: 16) {
                CustomSectionView(header: Loc.SharedDictionaries.privateDictionary, hPadding: .zero) {
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
                                Text(Loc.SharedDictionaries.privateDictionary)
                                    .font(.headline)

                                Text(Loc.SharedDictionaries.saveToPersonalDictionary)
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
                    CustomSectionView(header: Loc.SharedDictionaries.sharedDictionaries, hPadding: .zero) {
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
                                            Text(Loc.SharedDictionaries.collaboratorsCount(dictionary.collaborators.count))
                                                .font(.caption)
                                                .foregroundStyle(.secondary)

                                            if dictionary.isOwner {
                                                Text(Loc.SharedDictionaries.owner)
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
                        header: Loc.SharedDictionaries.sharedDictionaries,
                        footer: Loc.SharedDictionaries.createSharedDictionaryCollaborate
                    ) {
                        ActionButton(
                            Loc.SharedDictionaries.createSharedDictionary,
                            systemImage: "plus.circle"
                        ) {
                            if dictionaryService.canCreateMoreSharedDictionaries() {
                                showingAddDictionary = true
                            } else {
                                PaywallService.shared.isShowingPaywall = true
                            }
                        }
                        .padding(.bottom, 12)
                    }
                }
            }
            .padding(12)
        } navigationBar: {
            NavigationBarView(title: Loc.SharedDictionaries.SharedDictionarySelection.selectDictionary)
        }
        .groupedBackground()
        .sheet(isPresented: $showingAddDictionary) {
            AddSharedDictionaryView()
                .presentationCornerRadius(24)
        }
        .withPaywall()
        .onAppear {
            dictionaryService.setupSharedDictionariesListener()
        }
    }
} 
