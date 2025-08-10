//
//  SubscriptionView.swift
//  My Dictionary (macOS)
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import SwiftUI
import StoreKit

struct SubscriptionView: View {
    @StateObject private var subscriptionService = SubscriptionService.shared
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPlan: SubscriptionPlan = .yearly
    
    var body: some View {
        VStack(spacing: 32) {
            // Header
            headerSection
            
            // Features
            featuresSection
            
            // Plans
            plansSection
            
            // Purchase Button
            purchaseButton
            
            // Restore Button
            restoreButton
            
            // Terms and Privacy
            termsSection
            
            Spacer()
        }
        .padding(32)
        .frame(maxWidth: 600)
        .background(.background)
        .onAppear {
            AnalyticsService.shared.logEvent(.subscriptionScreenOpened)
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "crown.fill")
                .font(.system(size: 80))
                .foregroundStyle(.yellow)
            
            Text("Unlock Pro Features")
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            Text("Get unlimited access to all features and sync across all your devices")
                .font(.title3)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Features Section
    
    private var featuresSection: some View {
        VStack(spacing: 16) {
            Text("Pro Features")
                .font(.title2)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ForEach(SubscriptionFeature.allCases, id: \.self) { feature in
                    FeatureCard(feature: feature)
                }
            }
        }
    }
    
    // MARK: - Plans Section
    
    private var plansSection: some View {
        VStack(spacing: 16) {
            Text("Choose Your Plan")
                .font(.title2)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 16) {
                ForEach(SubscriptionPlan.allCases, id: \.self) { plan in
                    PlanCard(
                        plan: plan,
                        isSelected: selectedPlan == plan,
                        onTap: {
                            selectedPlan = plan
                        }
                    )
                }
            }
        }
    }
    
    // MARK: - Purchase Button
    
    private var purchaseButton: some View {
        Button {
            Task {
                await purchaseSelectedPlan()
            }
        } label: {
            HStack {
                if subscriptionService.isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                        .tint(.white)
                } else {
                    Text("Upgrade to Pro")
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(.accent)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .disabled(subscriptionService.isLoading)
    }
    
    // MARK: - Restore Button
    
    private var restoreButton: some View {
        Button("Restore Purchases") {
            Task {
                await restorePurchases()
            }
        }
        .font(.body)
        .foregroundStyle(.secondary)
        .disabled(subscriptionService.isLoading)
    }
    
    // MARK: - Terms Section
    
    private var termsSection: some View {
        VStack(spacing: 8) {
            Text("By upgrading, you agree to our Terms of Service and Privacy Policy")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            HStack(spacing: 16) {
                Button("Terms of Service") {
                    // Open terms URL
                }
                .font(.caption)
                .foregroundStyle(.accent)
                
                Button("Privacy Policy") {
                    // Open privacy URL
                }
                .font(.caption)
                .foregroundStyle(.accent)
            }
        }
    }
    
    // MARK: - Actions
    
    private func purchaseSelectedPlan() async {
        do {
            try await subscriptionService.purchasePlan(selectedPlan)
            if subscriptionService.isProUser {
                dismiss()
            }
        } catch {
            // Show error alert
            print("Purchase failed: \(error)")
        }
    }
    
    private func restorePurchases() async {
        do {
            try await subscriptionService.restorePurchases()
            if subscriptionService.isProUser {
                dismiss()
            }
        } catch {
            // Show error alert
            print("Restore failed: \(error)")
        }
    }
}

// MARK: - Feature Card

struct FeatureCard: View {
    let feature: SubscriptionFeature
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: feature.iconName)
                    .font(.title2)
                    .foregroundStyle(.accent)
                
                Text(feature.displayName)
                    .font(.headline)
                    .fontWeight(.medium)
            }
            
            Text(feature.description)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.leading)
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

// MARK: - Plan Card

struct PlanCard: View {
    let plan: SubscriptionPlan
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(plan.displayName)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(plan.price)
                        .font(.title3)
                        .foregroundStyle(.secondary)
                    
                    if let savings = plan.savings {
                        Text(savings)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.green)
                    }
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(isSelected ? .accent : .secondary)
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.background)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? .accent : .secondary.opacity(0.3), lineWidth: 2)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    SubscriptionView()
}
