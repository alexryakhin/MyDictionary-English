//
//  AdvancedPaywallView.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import SwiftUI
import RevenueCat

struct AdvancedPaywallView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.openURL) var openURL

    @StateObject private var subscriptionService = SubscriptionService.shared
    @StateObject private var paywallService = PaywallService.shared

    @State private var selectedPlan: SubscriptionPlan?
    @State private var isLoading = false
    @State private var showingRestoreAlert = false
    @State private var restoreMessage = ""
    @State private var animateHeader = false
    @State private var animateFeatures = false
    @State private var animatePlans = false
    
    var body: some View {
        ScrollViewWithCustomNavBar {
            VStack(spacing: 0) {
                // Hero section with gradient background
                heroSection

                // Features with animations
                featuresSection
                    .opacity(animateFeatures ? 1 : 0)
                    .offset(y: animateFeatures ? 0 : 50)

                // Plans with animations
                plansSection
                    .opacity(animatePlans ? 1 : 0)
                    .offset(y: animatePlans ? 0 : 50)

                // Action buttons
                actionButtonsSection

                // Social proof
                socialProofSection

                // Terms and privacy
                termsSection
            }
        } navigationBar: {
            HeaderButton(icon: "xmark") {
                paywallService.dismissPaywall()
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .background {
            LinearGradient(
                colors: [
                    Color.accentColor.opacity(0.15),
                    Color.accentColor.opacity(0.1),
                    Color.systemBackground
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        }
        .onAppear {
            startAnimations()
            // Set default plan if none selected
            if selectedPlan == nil {
                selectedPlan = subscriptionService.defaultPlan
            }
        }
        .alert("Restore Purchases", isPresented: $showingRestoreAlert) {
            Button("OK") { }
        } message: {
            Text(restoreMessage)
        }
    }
    
    // MARK: - Hero Section
    
    private var heroSection: some View {
        VStack(spacing: 20) {
            // Animated crown
            Image(.iconRounded)
                .resizable()
                .scaledToFit()
                .frame(width: 90, height: 90)
                .scaleEffect(animateHeader ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: animateHeader)
                .padding(.top, 30)
            
            VStack(spacing: 12) {
                Text("Upgrade to Pro")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text("Join thousands of users who've transformed their vocabulary learning")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
            }
            
            // Value proposition
            HStack(spacing: 12) {
                ValuePropositionCard(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Track Progress",
                    subtitle: "See your improvement"
                )
                
                ValuePropositionCard(
                    icon: "person.3.fill",
                    title: "Collaborate",
                    subtitle: "Learn with others"
                )
            }
            .padding(.horizontal, 16)
        }
        .padding(.bottom, 30)
    }
    
    // MARK: - Features Section
    
    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Everything you need to master vocabulary")
                .font(.title2)
                .fontWeight(.semibold)
                .padding(.horizontal, 16)

            VStack(spacing: 12) {
                ForEach(Array(SubscriptionFeature.allCases.enumerated()), id: \.element) { index, feature in
                    AdvancedFeatureCard(
                        feature: feature,
                        delay: Double(index) * 0.1
                    )
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 20)
    }
    
    // MARK: - Plans Section
    
    private var plansSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Choose Your Plan")
                .font(.title2)
                .fontWeight(.semibold)
                .padding(.horizontal, 16)

            VStack(spacing: 12) {
                ForEach(subscriptionService.availablePlans, id: \.id) { plan in
                    AdvancedPlanCard(
                        plan: plan,
                        isSelected: selectedPlan?.id == plan.id,
                        action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                selectedPlan = plan
                            }
                        }
                    )
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 20)
    }
    
    // MARK: - Action Buttons Section
    
    private var actionButtonsSection: some View {
        VStack(spacing: 16) {
            // Subscribe button with gradient
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
                        Text("Start \(selectedPlan?.displayName ?? "Pro")")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    LinearGradient(
                        colors: [Color.accentColor, Color.accentColor.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: Color.accentColor.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .buttonStyle(.plain)
            .disabled(isLoading)
            .scaleEffect(isLoading ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isLoading)
            
            // Restore button
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
        .padding(.horizontal, 16)
        .padding(.vertical, 20)
    }
    
    // MARK: - Social Proof Section
    
    private var socialProofSection: some View {
        VStack(spacing: 16) {
            Text("Trusted by learners worldwide")
                .font(.headline)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
            
            HStack(spacing: 20) {
                SocialProofCard(
                    number: "4.8",
                    label: "App Store Rating"
                )
                
                SocialProofCard(
                    number: "2K+",
                    label: "Active Users"
                )
                
                SocialProofCard(
                    number: "10K+",
                    label: "Words Added"
                )
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 20)
    }
    
    // MARK: - Terms Section
    
    private var termsSection: some View {
        VStack(spacing: 8) {
            Text("By subscribing, you agree to our Terms of Service and Privacy Policy")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            HStack(spacing: 16) {
                Button("Terms of Service") {
                    openURL(GlobalConstant.termsOfUse)
                }
                .buttonStyle(.plain)
                .font(.caption)
                .foregroundStyle(.accent)
                
                Button("Privacy Policy") {
                    openURL(GlobalConstant.privacyPolicy)
                }
                .buttonStyle(.plain)
                .font(.caption)
                .foregroundStyle(.accent)
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 40)
    }
    
    // MARK: - Actions
    
    private func startAnimations() {
        withAnimation(.easeOut(duration: 0.8).delay(0.2)) {
            animateHeader = true
        }
        
        withAnimation(.easeOut(duration: 0.8).delay(0.4)) {
            animateFeatures = true
        }
        
        withAnimation(.easeOut(duration: 0.8).delay(0.6)) {
            animatePlans = true
        }
    }
    
    private func purchaseSelectedPlan() async {
        guard let plan = selectedPlan else {
            errorReceived(CoreError.internalError(.noActiveSubscription))
            return
        }
        
        isLoading = true
        
        do {
            try await subscriptionService.purchasePlan(plan)
            paywallService.handlePurchaseCompleted()
            dismiss()
        } catch {
            errorReceived(error)
        }
        
        isLoading = false
    }
    
    private func restorePurchases() async {
        isLoading = true
        
        do {
            let success = await paywallService.handleRestorePurchases()
            if success {
                paywallService.handlePurchaseCompleted()
                dismiss()
            } else {
                restoreMessage = "No active subscriptions found. Please check your App Store account."
                showingRestoreAlert = true
            }
        } catch {
            restoreMessage = "Failed to restore purchases: \(error.localizedDescription)"
            showingRestoreAlert = true
        }
        
        isLoading = false
    }
}

// MARK: - Supporting Views

struct ValuePropositionCard: View {
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(Color.accentColor)

            VStack(spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.medium)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, 16)
        .background(Color.secondarySystemGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct AdvancedFeatureCard: View {
    let feature: SubscriptionFeature
    let delay: Double
    @State private var isVisible = false
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: feature.iconName)
                .font(.title2)
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.accentColor, Color.accentColor.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 28)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(feature.displayName)
                    .font(.subheadline)
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
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 20)
        .onAppear {
            withAnimation(.easeOut(duration: 0.6).delay(delay)) {
                isVisible = true
            }
        }
    }
}

struct AdvancedPlanCard: View {
    let plan: SubscriptionPlan
    let isSelected: Bool
    let action: VoidHandler
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(plan.displayName)
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        if let savings = plan.savings {
                            Text(savings)
                                .font(.caption)
                                .fontWeight(.medium)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(
                                    LinearGradient(
                                        colors: [.green, .green.opacity(0.8)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
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

struct SocialProofCard: View {
    let number: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(number)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(Color.accentColor)
            
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    AdvancedPaywallView()
}
