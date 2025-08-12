//
//  SharedDictionariesListView.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import SwiftUI
import RevenueCatUI

struct SharedDictionariesListView: View {
    @Environment(\.dismiss) private var dismiss

    @StateObject private var paywallService = PaywallService.shared
    @StateObject private var subscriptionService = SubscriptionService.shared
    @StateObject private var dictionaryService = DictionaryService.shared
    @State private var showingAddDictionary = false
    @Binding var navigationPath: NavigationPath
    
    private var userOwnedDictionaryCount: Int {
        dictionaryService.getUserOwnedDictionaryCount()
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Show user's dictionary count and limit
                if !subscriptionService.isProUser {
                    CustomSectionView(header: "Your Dictionaries") {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(userOwnedDictionaryCount) of 1 dictionary created")
                                .font(.headline)
                            Text("Free users can create one shared dictionary")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } trailingContent: {
                        if userOwnedDictionaryCount >= 1 {
                            HeaderButton(text: "Upgrade to Pro") {
                                paywallService.isShowingPaywall = true
                            }
                        }
                    }
                }

                CustomSectionView(header: "Dictionaries") {
                    if dictionaryService.sharedDictionaries.isEmpty {
                        ContentUnavailableView(
                            "No Shared Dictionaries",
                            systemImage: "person.2",
                            description: Text(
                                dictionaryService.canCreateMoreSharedDictionaries()
                                    ? "Create a shared dictionary to collaborate with others"
                                    : "Free users can create one shared dictionary. Upgrade to Pro for unlimited dictionaries."
                            )
                        )
                    } else {
                        ListWithDivider(dictionaryService.sharedDictionaries) { dictionary in
                            Button {
                                navigationPath.append(NavigationDestination.sharedDictionaryWords(dictionary))
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
                                                    .foregroundStyle(.green)
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
                            .buttonStyle(.plain)
                        }
                    }
                } trailingContent: {
                    if dictionaryService.canCreateMoreSharedDictionaries() {
                        HeaderButton(text: "Add", icon: "plus", style: .borderedProminent) {
                            showingAddDictionary = true
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
        }
        .refreshable {
            await refreshSharedDictionaries()
        }
        .groupedBackground()
        .navigation(
            title: "Shared Dictionaries",
            mode: .inline,
            showsBackButton: true
        )
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
    
    private func refreshSharedDictionaries() async {
        print("🔄 [SharedDictionariesListView] Pull-to-refresh triggered")
        
        // Force a refresh of the shared dictionaries
        dictionaryService.refreshSharedDictionaries()
        
        // Add a small delay to ensure the refresh completes
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        print("✅ [SharedDictionariesListView] Pull-to-refresh completed")
    }
} 
