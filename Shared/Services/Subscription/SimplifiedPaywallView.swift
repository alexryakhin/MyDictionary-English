//
//  SimplifiedPaywallView.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/9/25.
//

import SwiftUI
import RevenueCat

struct SimplifiedPaywallView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.openURL) var openURL

    @StateObject private var subscriptionService = SubscriptionService.shared
    @StateObject private var paywallService = PaywallService.shared
    @StateObject private var paywallContentService = PaywallContentService.shared

    @State private var selectedPlan: SubscriptionPlan?
    @State private var isLoading = false
    @State private var showingRestoreAlert = false
    @State private var restoreMessage = ""
    @State private var safariURL: URL?

    // MARK: - Content Properties

    private var title: String {
        paywallContentService.aiContent?.title ?? Loc.Subscription.Paywall.Generic.title
    }

    private var subtitle: String {
        paywallContentService.aiContent?.subtitle ?? Loc.Subscription.Paywall.Generic.subtitle
    }

    private var benefits: [PaywallBenefit] {
        if let aiBenefits = paywallContentService.aiContent?.benefits {
            return aiBenefits.map { PaywallBenefit(from: $0) }
        } else {
            return [
                PaywallBenefit(
                    title: Loc.Subscription.Paywall.Generic.benefit1Title,
                    description: Loc.Subscription.Paywall.Generic.benefit1Description,
                    icon: "sparkles"
                ),
                PaywallBenefit(
                    title: Loc.Subscription.Paywall.Generic.benefit2Title,
                    description: Loc.Subscription.Paywall.Generic.benefit2Description,
                    icon: "speaker.wave.3"
                ),
                PaywallBenefit(
                    title: Loc.Subscription.Paywall.Generic.benefit3Title,
                    description: Loc.Subscription.Paywall.Generic.benefit3Description,
                    icon: "folder.fill"
                )
            ]
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                heroSection
                benefitsSection
                plansSection
                termsSection
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 32)
        }
        .withGradientBackground()
        .safeAreaBarIfAvailable(edge: .top, alignment: .trailing) {
            HeaderButton(icon: "xmark") {
                paywallService.dismissPaywall()
            }
            .padding(12)
        }
        .safeAreaBarIfAvailable {
            actionButtonsSection
        }
        .onAppear {
            if selectedPlan == nil {
                selectedPlan = subscriptionService.defaultPlan
            }
        }
        .safari(url: $safariURL)
        .alert(Loc.Subscription.Paywall.restoreSubscription, isPresented: $showingRestoreAlert) {
            Button(Loc.Actions.ok) { }
        } message: {
            Text(restoreMessage)
        }
    }

    // MARK: - Hero Section

    private var heroSection: some View {
        VStack(spacing: 16) {
            // App Icon
            Image(.illustrationPremium)
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 240)
                .padding(20)

            VStack(spacing: 12) {
                Text(title)
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.primary)

                Text(subtitle)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 16)
            }
        }
    }

    // MARK: - Benefits Section

    private var benefitsSection: some View {
        VStack(spacing: 16) {
            ForEach(Array(benefits.enumerated()), id: \.offset) { index, benefit in
                BenefitCard(
                    benefit: benefit,
                    index: index
                )
            }
        }
    }

    // MARK: - Plans Section

    private var plansSection: some View {
        VStack(spacing: 16) {
            Text(Loc.Subscription.Paywall.chooseYourPlan)
                .font(.headline)
                .fontWeight(.semibold)

            VStack(spacing: 12) {
                ForEach(subscriptionService.availablePlans) { plan in
                    PlanCard(
                        plan: plan,
                        isSelected: selectedPlan?.id == plan.id,
                        action: { selectedPlan = plan }
                    )
                }
            }
        }
    }

    // MARK: - Action Buttons

    private var actionButtonsSection: some View {
        VStack(spacing: 8) {
            // Subscribe button - shows "Try for Free" if trial is available
            AsyncActionButton(
                Loc.Subscription.Paywall.startProSubscription,
                systemImage: "book.fill",
                style: .borderedProminent
            ) {
                await startSubscription()
            }

            // Restore button
            AsyncActionButton(
                Loc.Subscription.Paywall.restoreSubscription,
                style: .bordered
            ) {
                await restoreSubscription()
            }
        }
        .padding(vertical: 12, horizontal: 16)
    }

    // MARK: - Terms Section

    private var termsSection: some View {
        // Terms of Service & Privacy Policy
        HStack(spacing: 4) {
            Button(Loc.Subscription.Paywall.termsOfService) {
                #if os(macOS)
                openURL(GlobalConstant.termsOfUse)
                #else
                safariURL = GlobalConstant.termsOfUse
                #endif
            }
            .buttonStyle(.plain)
            Text(Loc.Subscription.Paywall.andConjunction)
                .foregroundStyle(.secondary)
            Button(Loc.Subscription.Paywall.privacyPolicy) {
                #if os(macOS)
                openURL(GlobalConstant.privacyPolicy)
                #else
                safariURL = GlobalConstant.privacyPolicy
                #endif
            }
            .buttonStyle(.plain)
        }
        .font(.caption)
        .padding(.horizontal, 16)
    }

    // MARK: - Actions

    private func startSubscription() async {
        guard let plan = selectedPlan else {
            errorReceived(CoreError.internalError(.noActiveSubscription))
            return
        }

        isLoading = true

        do {
            try await subscriptionService.purchasePlan(plan)
            // Only call handlePurchaseCompleted if purchase was successful
            paywallService.handlePurchaseCompleted()
            dismiss()
        } catch {
            // Purchase failed or was cancelled - call handlePurchaseFailed
            paywallService.handlePurchaseFailed()
            errorReceived(error)
        }

        isLoading = false
    }

    private func restoreSubscription() async {
        isLoading = true

        let success = await paywallService.handleRestorePurchases()
        if success {
            paywallService.handlePurchaseCompleted()
            dismiss()
        } else {
            restoreMessage = Loc.Subscription.Paywall.noActiveSubscriptionsFound
            showingRestoreAlert = true
        }

        isLoading = false
    }

    private func openTerms() {
        if let url = URL(string: "https://mydictionary.app/terms") {
            safariURL = url
        }
    }

    private func openPrivacy() {
        if let url = URL(string: "https://mydictionary.app/privacy") {
            safariURL = url
        }
    }
}

// MARK: - Supporting Views

struct BenefitCard: View {
    let benefit: PaywallBenefit
    let index: Int

    var body: some View {
        HStack(spacing: 16) {
            // Icon
            Image(systemName: benefit.icon)
                .font(.title2)
                .foregroundColor(.accentColor)
                .frame(width: 32, height: 32)

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(benefit.title)
                    .font(.headline)
                    .fontWeight(.semibold)

                Text(benefit.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

struct PlanCard: View {
    let plan: SubscriptionPlan
    let isSelected: Bool
    let action: VoidHandler

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(plan.displayName)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    if let pricePerMonth = plan.pricePerMonth {
                        Text(pricePerMonth + "/" + Loc.Subscription.Period.month)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    if plan.period == .year {
                        TagView(text: Loc.Subscription.Paywall.bestValue)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .trailing, spacing: 4) {
                    Text(plan.price)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(
                        plan.period == .year
                        ? Loc.Subscription.Paywall.annually
                        : Loc.Subscription.Paywall.monthly
                    )
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }

                Image(systemName: isSelected ? "inset.filled.circle" : "circle")
                    .font(.title2)
                    .foregroundStyle(isSelected ? Color.accentColor : .secondary)
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isSelected ? Color.accentColor.opacity(0.1) : Color.secondarySystemGroupedBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isSelected)
    }
}

// MARK: - Supporting Models

struct PaywallBenefit {
    let title: String
    let description: String
    let icon: String

    init(title: String, description: String, icon: String) {
        self.title = title
        self.description = description
        self.icon = icon
    }

    init(from aiBenefit: AIPaywallBenefit) {
        self.title = aiBenefit.feature.displayName
        self.description = aiBenefit.personalizedDescription
        self.icon = aiBenefit.feature.iconName
    }
}
