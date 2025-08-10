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

    var body: some View {
        ScrollView {
            CustomSectionView(header: "Dictionaries") {
                if dictionaryService.sharedDictionaries.isEmpty {
                    ContentUnavailableView(
                        "No Shared Dictionaries",
                        systemImage: "person.2",
                        description: Text("Create a shared dictionary to collaborate with others")
                    )
                } else {
                    ListWithDivider(dictionaryService.sharedDictionaries) { dictionary in
                        Button {
                            navigationPath.append(NavigationDestination.sharedDictionaryDetails(dictionary))
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
                    }
                }
            } trailingContent: {
                HeaderButton(text: "Add", icon: "plus", style: .borderedProminent) {
                    if subscriptionService.isProUser {
                        showingAddDictionary = true
                    } else {
                        paywallService.isShowingPaywall = true
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
            if subscriptionService.isProUser {
                AddSharedDictionaryView()
                    .presentationCornerRadius(24)
            } else {
                PaywallView()
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
