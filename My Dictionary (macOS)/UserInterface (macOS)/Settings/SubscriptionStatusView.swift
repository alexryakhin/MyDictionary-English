//
//  SubscriptionStatusView.swift
//  My Dictionary (macOS)
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import SwiftUI
import RevenueCatUI

struct SubscriptionStatusView: View {
    @StateObject private var subscriptionService = SubscriptionService.shared
    @State private var showingSubscriptionView = false
    
    var body: some View {
        VStack(spacing: 16) {
            if subscriptionService.isProUser {
                proUserView
            } else {
                freeUserView
            }
        }
        .padding(.bottom, 12)
        .sheet(isPresented: $showingSubscriptionView) {
            MyPaywallView()
        }
    }
    
    // MARK: - Pro User View
    
    private var proUserView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "crown.fill")
                        .foregroundStyle(.yellow)
                    Text("Pro User")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                
                if let plan = subscriptionService.currentPlan {
                    Text(plan.displayName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
                .font(.title2)
        }
        .padding(16)
        .background(.background)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(.secondary.opacity(0.3), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Free User View
    
    private var freeUserView: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Free Plan")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("Limited features available")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "crown")
                    .foregroundStyle(.secondary)
                    .font(.title2)
            }
            
            Button {
                showingSubscriptionView = true
            } label: {
                Text("Upgrade to Pro")
                    .font(.body)
                    .fontWeight(.medium)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(.accent)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(16)
        .background(.background)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(.secondary.opacity(0.3), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    SubscriptionStatusView()
        .padding()
}
