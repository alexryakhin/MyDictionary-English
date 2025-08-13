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
    @StateObject private var navigationManager: NavigationManager = .shared
    @State private var showingAddDictionary = false

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
                        .frame(maxWidth: .infinity, alignment: .leading)
                    } trailingContent: {
                        if userOwnedDictionaryCount >= 1 {
                            HeaderButton("Upgrade to Pro", size: .small) {
                                paywallService.isShowingPaywall = true
                            }
                        }
                    }
                }

                CustomSectionView(header: "Dictionaries", hPadding: .zero) {
                    if dictionaryService.sharedDictionaries.isEmpty {
                        ContentUnavailableView(
                            "No Shared Dictionaries",
                            systemImage: "person.2",
                            description: Text("Create a shared dictionary to collaborate with others")
                        )
                    } else {
                        ListWithDivider(dictionaryService.sharedDictionaries) { dictionary in
                            SharedDictionariesListCellView(dictionary: dictionary)
                                .onTap {
                                    navigationManager.navigationPath.append(NavigationDestination.sharedDictionaryWords(dictionary))
                                }
                        }
                    }
                } trailingContent: {
                    if dictionaryService.canCreateMoreSharedDictionaries() {
                        HeaderButton("Add", icon: "plus", size: .small, style: .borderedProminent) {
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
