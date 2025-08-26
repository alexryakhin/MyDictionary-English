//
//  SharedDictionariesListView.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import SwiftUI

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
                    CustomSectionView(header: Loc.SharedDictionaries.yourDictionaries) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(Loc.Plurals.SharedDictionaries.dictionaryCountCreated(userOwnedDictionaryCount))
                                .font(.headline)
                            Text(Loc.SharedDictionaries.freeUsersOneDictionary)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    } trailingContent: {
                        if userOwnedDictionaryCount >= 1 {
                            HeaderButton(Loc.Subscription.Paywall.upgradeToPro, size: .small) {
                                paywallService.isShowingPaywall = true
                            }
                        }
                    }
                }

                CustomSectionView(header: Loc.SharedDictionaries.dictionaries, hPadding: .zero) {
                    if dictionaryService.sharedDictionaries.isEmpty {
                        ContentUnavailableView(
                            Loc.SharedDictionaries.noSharedDictionaries,
                            systemImage: "person.2",
                            description: Text(Loc.SharedDictionaries.createSharedDictionaryCollaborate)
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
                        HeaderButton(Loc.Actions.add, icon: "plus", size: .small, style: .borderedProminent) {
                            if dictionaryService.canCreateMoreSharedDictionaries() {
                                showingAddDictionary = true
                            } else {
                                PaywallService.shared.isShowingPaywall = true
                            }
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
            title: Loc.Settings.sharedDictionaries,
            mode: .inline,
            showsBackButton: true
        )
        .sheet(isPresented: $showingAddDictionary) {
            AddSharedDictionaryView()
                .presentationCornerRadius(24)
        }
        .withPaywall()
        .onAppear {
            dictionaryService.setupSharedDictionariesListener()
        }
    }
    
    private func refreshSharedDictionaries() async {
        // Force a refresh of the shared dictionaries
        dictionaryService.refreshSharedDictionaries()
        
        // Add a small delay to ensure the refresh completes
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
    }
} 
