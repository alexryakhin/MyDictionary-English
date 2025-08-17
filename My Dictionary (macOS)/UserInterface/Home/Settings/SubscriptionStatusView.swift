//
//  SubscriptionStatusView.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import SwiftUI

struct SubscriptionStatusView: View {
    @StateObject private var subscriptionService = SubscriptionService.shared

    var body: some View {
        VStack(spacing: 8) {
            if subscriptionService.isProUser {
                proUserView
            } else {
                freeUserView
            }
        }
        .padding(.bottom, 12)
    }
    
    // MARK: - Pro User View
    
    private var proUserView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "crown.fill")
                        .foregroundStyle(.yellow)
                    Text(Loc.Paywall.proUser.localized)
                        .font(.body)
                        .fontWeight(.semibold)
                }
                
                if let plan = subscriptionService.currentPlan {
                    Text(plan.displayName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            Image(systemName: "checkmark.square.fill")
                .foregroundStyle(.accent)
                .font(.title2)
        }
        .padding(vertical: 12, horizontal: 16)
        .clippedWithBackground(Color.tertiarySystemGroupedBackground, cornerRadius: 16)
    }
    
    // MARK: - Free User View
    
    private var freeUserView: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(Loc.Paywall.freePlan.localized)
                        .font(.body)
                        .fontWeight(.semibold)
                    
                    Text(Loc.Paywall.limitedFeaturesAvailable.localized)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "crown")
                    .foregroundStyle(.secondary)
                    .font(.title2)
            }
            
            ActionButton("Upgrade to Pro") {
                PaywallService.shared.isShowingPaywall = true
            }
        }
        .padding(vertical: 12, horizontal: 16)
        .clippedWithBackground(Color.tertiarySystemGroupedBackground, cornerRadius: 16)
    }
}

#Preview {
    SubscriptionStatusView()
        .padding()
}
