//
//  MacOSPaywallView.swift
//  My Dictionary (macOS)
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import SwiftUI
import RevenueCat

enum MacOSPaywall {

    struct ContentView: View {
        @StateObject private var subscriptionService = SubscriptionService.shared
        @Environment(\.dismiss) var dismiss
        @State private var selectedPlan: SubscriptionPlan = .yearly
        @State private var isLoading = false

        var body: some View {
            VStack(spacing: 0) {
                // Header
                headerView

                ScrollView {
                    VStack(spacing: 32) {
                        // Features section
                        featuresSection

                        // Subscription plans
                        subscriptionPlansSection

                        // Action buttons
                        actionButtonsSection
                    }
                    .padding(32)
                }
            }
            .frame(minWidth: 600, minHeight: 700)
            .background(Color.systemGroupedBackground)
        }

        // MARK: - Header View

        private var headerView: some View {
            VStack(spacing: 16) {
                HStack {
                    Text("Upgrade to Pro")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Spacer()

                    Button {
                        PaywallService.shared.dismissPaywall()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }

                Text("Unlock all features and take your vocabulary learning to the next level")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
            }
            .padding(32)
            .background(Color.secondarySystemGroupedBackground)
        }

        // MARK: - Features Section

        private var featuresSection: some View {
            VStack(alignment: .leading, spacing: 16) {
                Text("Pro Features")
                    .font(.title2)
                    .fontWeight(.semibold)

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

        // MARK: - Subscription Plans Section

        private var subscriptionPlansSection: some View {
            VStack(alignment: .leading, spacing: 16) {
                Text("Choose Your Plan")
                    .font(.title2)
                    .fontWeight(.semibold)

                VStack(spacing: 12) {
                    ForEach(SubscriptionPlan.allCases, id: \.self) { plan in
                        PlanCard(
                            plan: plan,
                            isSelected: selectedPlan == plan,
                            action: {
                                selectedPlan = plan
                            }
                        )
                    }
                }
            }
        }

        // MARK: - Action Buttons Section

        private var actionButtonsSection: some View {
            VStack(spacing: 16) {
                Button {
                    Task {
                        await purchaseSelectedPlan()
                    }
                } label: {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                                .tint(.white)
                        } else {
                            Text("Subscribe to \(selectedPlan.displayName)")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(isLoading)
                .buttonStyle(.plain)

                Button {
                    Task {
                        await restorePurchases()
                    }
                } label: {
                    Text("Restore Purchases")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
                .disabled(isLoading)
                .buttonStyle(.plain)
            }
        }

        // MARK: - Actions

        private func purchaseSelectedPlan() async {
            isLoading = true

            do {
                try await subscriptionService.purchasePlan(selectedPlan)
                PaywallService.shared.handlePurchaseCompleted()
                dismiss()
            } catch {
                errorReceived(error)
            }

            isLoading = false
        }

        private func restorePurchases() async {
            isLoading = true

            do {
                try await subscriptionService.restorePurchases()
                if subscriptionService.isProUser {
                    PaywallService.shared.handlePurchaseCompleted()
                    dismiss()
                } else {
                    errorReceived(CoreError.internalError(.noActiveSubscription))
                }
            } catch {
                errorReceived(error)
            }

            isLoading = false
        }
    }

    // MARK: - Feature Card

    struct FeatureCard: View {
        let feature: SubscriptionFeature

        var body: some View {
            HStack(spacing: 12) {
                Image(systemName: feature.iconName)
                    .font(.title2)
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 4) {
                    Text(feature.displayName)
                        .font(.headline)
                        .fontWeight(.medium)

                    Text(feature.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer()
            }
            .padding(16)
            .background(Color.secondarySystemGroupedBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - Plan Card

    struct PlanCard: View {
        let plan: SubscriptionPlan
        let isSelected: Bool
        let action: VoidHandler

        var body: some View {
            Button(action: action) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(plan.displayName)
                                .font(.headline)
                                .fontWeight(.semibold)

                            if let savings = plan.savings {
                                Text(savings)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(Color.green)
                                    .foregroundStyle(.white)
                                    .clipShape(Capsule())
                            }
                        }

                        Text(plan.price)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundStyle(isSelected ? Color.accentColor : .secondary)
                }
                .padding(16)
                .background(isSelected ? Color.accentColor.opacity(0.1) : Color.secondarySystemGroupedBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
        }
    }
}

#Preview {
    MacOSPaywall.ContentView()
}
