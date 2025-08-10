//
//  SubscriptionView.swift
//  My Dictionary
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
        ScrollView {
            VStack(spacing: 24) {
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
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
        }
        .groupedBackground()
        .navigation(title: "Upgrade to Pro", mode: .inline)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    dismiss()
                }
            }
        }
        .onAppear {
            AnalyticsService.shared.logEvent(.subscriptionScreenOpened)
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "crown.fill")
                .font(.system(size: 60))
                .foregroundStyle(.yellow)
            
            Text("Unlock Pro Features")
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            Text("Get unlimited access to all features and sync across all your devices")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Features Section
    
    private var featuresSection: some View {
        VStack(spacing: 16) {
            Text("Pro Features")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            LazyVStack(spacing: 12) {
                ForEach(SubscriptionFeature.allCases, id: \.self) { feature in
                    FeatureRow(feature: feature)
                }
            }
        }
    }
    
    // MARK: - Plans Section
    
    private var plansSection: some View {
        VStack(spacing: 16) {
            Text("Choose Your Plan")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            LazyVStack(spacing: 12) {
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
            AlertCenter.shared.showAlert(with: .error(
                title: "Purchase Failed",
                message: error.localizedDescription
            ))
        }
    }
    
    private func restorePurchases() async {
        do {
            try await subscriptionService.restorePurchases()
            if subscriptionService.isProUser {
                dismiss()
            } else {
                AlertCenter.shared.showAlert(with: .info(
                    title: "No Purchases Found",
                    message: "No previous purchases were found to restore."
                ))
            }
        } catch {
            AlertCenter.shared.showAlert(with: .error(
                title: "Restore Failed",
                message: error.localizedDescription
            ))
        }
    }
}

// MARK: - Feature Row

extension SubscriptionView {
    struct FeatureRow: View {
        let feature: SubscriptionFeature

        var body: some View {
            HStack(spacing: 12) {
                Image(systemName: feature.iconName)
                    .font(.title2)
                    .foregroundStyle(.accent)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text(feature.displayName)
                        .font(.body)
                        .fontWeight(.medium)

                    Text(feature.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .padding(.vertical, 4)
        }
    }
}

// MARK: - Plan Card

struct PlanCard: View {
    let plan: SubscriptionPlan
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(plan.displayName)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(plan.price)
                        .font(.body)
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
            .padding(16)
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
    NavigationView {
        SubscriptionView()
    }
}
