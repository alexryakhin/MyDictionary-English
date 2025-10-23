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
    @StateObject private var onboardingService = OnboardingService.shared

    @State private var selectedPlan: SubscriptionPlan?
    @State private var isLoading = false
    @State private var showingRestoreAlert = false
    @State private var restoreMessage = ""
    @State private var animateHeader = false
    @State private var animateFeatures = false
    @State private var animatePlans = false
    @State private var safariURL: URL?

    // MARK: - Personalized Content
    
    private var personalizedTitle: String {
        guard let profile = onboardingService.userProfile else {
            return Loc.Subscription.Paywall.upgradeToPro
        }
        
        let userName = profile.userName.isEmpty ? "there" : profile.userName
        return Loc.Subscription.Paywall.personalizedTitleMain(userName)
    }
    
    private var personalizedSubtitle: String {
        guard let profile = onboardingService.userProfile else {
            return Loc.Subscription.Paywall.joinThousandsUsers
        }
        
        let goals = profile.learningGoals
        let userType = profile.userType.rawValue
        let studyLanguages = profile.studyLanguages
        let primaryLanguage = studyLanguages.first?.language.displayName ?? "your target language"
        
        if goals.contains(.study) {
            return Loc.Subscription.Paywall.personalizedSubtitleStudyMain(primaryLanguage)
        } else if goals.contains(.work) {
            return Loc.Subscription.Paywall.personalizedSubtitleWorkMain(primaryLanguage)
        } else if goals.contains(.travel) {
            return Loc.Subscription.Paywall.personalizedSubtitleTravelMain(primaryLanguage)
        } else if goals.contains(.business) {
            return Loc.Subscription.Paywall.personalizedSubtitleBusinessMain(primaryLanguage)
        } else {
            return Loc.Subscription.Paywall.personalizedSubtitleDefaultMain(userType, primaryLanguage)
        }
    }
    
    private var personalizedFeatures: [SubscriptionFeature] {
        guard let profile = onboardingService.userProfile else {
            return SubscriptionFeature.allCases
        }
        
        var features = SubscriptionFeature.allCases
        
        // Prioritize features based on user goals and interests
        if profile.learningGoals.contains(.study) {
            // Move analytics to front for students
            if let analyticsIndex = features.firstIndex(of: .advancedAnalytics) {
                let analytics = features.remove(at: analyticsIndex)
                features.insert(analytics, at: 0)
            }
        }
        
        if profile.interests.contains(.technology) {
            // Move sync to front for tech-savvy users
            if let syncIndex = features.firstIndex(of: .aiQuizzes) {
                let sync = features.remove(at: syncIndex)
                features.insert(sync, at: 0)
            }
        }
        
        if profile.learningGoals.contains(.work) || profile.learningGoals.contains(.business) {
            // Move shared dictionaries to front for professional users
            if let sharedIndex = features.firstIndex(of: .createSharedDictionaries) {
                let shared = features.remove(at: sharedIndex)
                features.insert(shared, at: 0)
            }
        }
        
        return features
    }
    
    private var personalizedAchievements: [String] {
        guard let profile = onboardingService.userProfile else {
            return []
        }
        
        var achievements: [String] = []
        let studyLanguages = profile.studyLanguages
        let primaryLanguage = studyLanguages.first?.language.displayName ?? "your target language"
        
        // Based on weekly goal
        let dailyGoal = profile.weeklyWordGoal / 7
        achievements.append(Loc.Subscription.Paywall.achievementMasterWordsMain(dailyGoal * 7, primaryLanguage))
        
        // Based on user type and goals
        if profile.learningGoals.contains(.study) {
            achievements.append(Loc.Subscription.Paywall.achievementAcademicWritingMain(primaryLanguage))
        }
        if profile.learningGoals.contains(.work) {
            achievements.append(Loc.Subscription.Paywall.achievementProfessionalCommunicationMain(primaryLanguage))
        }
        if profile.learningGoals.contains(.travel) {
            achievements.append(Loc.Subscription.Paywall.achievementTravelConfidenceMain(primaryLanguage))
        }
        if profile.learningGoals.contains(.business) {
            achievements.append(Loc.Subscription.Paywall.achievementBusinessCommunicationMain(primaryLanguage))
        }
        
        // Based on interests
        if profile.interests.contains(.technology) {
            achievements.append(Loc.Subscription.Paywall.achievementTechVocabularyMain(primaryLanguage))
        }
        if profile.interests.contains(.business) {
            achievements.append(Loc.Subscription.Paywall.achievementBusinessContextsMain(primaryLanguage))
        }
        
        return achievements
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Hero section with gradient background
                heroSection

                // Features with animations
                featuresSection
                    .opacity(animateFeatures ? 1 : 0)
                    .offset(y: animateFeatures ? 0 : 50)

                // Personalized achievements section
                if !personalizedAchievements.isEmpty {
                    personalizedAchievementsSection
                        .opacity(animateFeatures ? 1 : 0)
                        .offset(y: animateFeatures ? 0 : 50)
                }

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
        }
        .withGradientBackground()
        .safeAreaBarIfAvailable(edge: .top, alignment: .trailing) {
            HeaderButton(icon: "xmark") {
                paywallService.dismissPaywall()
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .onAppear {
            startAnimations()
            // Set default plan if none selected
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
                Text(personalizedTitle)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                Text(personalizedSubtitle)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
            }

            // Value proposition
            HStack(spacing: 12) {
                ValuePropositionCard(
                    icon: "chart.line.uptrend.xyaxis",
                    title: Loc.Subscription.Paywall.trackProgress,
                    subtitle: Loc.Subscription.Paywall.seeYourImprovement
                )

                ValuePropositionCard(
                    icon: "person.3.fill",
                    title: Loc.Subscription.Paywall.collaborate,
                    subtitle: Loc.Subscription.Paywall.learnWithOthers
                )
            }
            .padding(.horizontal, 16)
        }
        .padding(.bottom, 30)
    }

    // MARK: - Features Section

    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(Loc.Subscription.Paywall.everythingYouNeedToMasterVocabulary)
                .font(.title2)
                .fontWeight(.semibold)
                .padding(.horizontal, 16)

            VStack(spacing: 12) {
                ForEach(Array(personalizedFeatures.enumerated()), id: \.element) { index, feature in
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

    // MARK: - Personalized Achievements Section

    private var personalizedAchievementsSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text(Loc.Subscription.Paywall.perfectForYourGoalsMain)
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(Loc.Subscription.Paywall.featuresTailoredToJourneyMain)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16)

            VStack(spacing: 12) {
                ForEach(Array(personalizedAchievements.enumerated()), id: \.offset) { index, achievement in
                    PersonalizedAchievementCard(
                        achievement: achievement,
                        icon: getAchievementIcon(for: achievement),
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
            Text(Loc.Subscription.Paywall.chooseYourPlan)
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
            // Registration benefits notice (only show if user is not authenticated)
            if !AuthenticationService.shared.isSignedIn {
                registrationBenefitsSection
            }
            
            // Subscribe button with gradient
            Button {
                Task {
                    await purchaseSelectedPlan()
                }
            } label: {
                HStack {
                    if isLoading {
                        LoaderView(color: .white)
                            .frame(width: 24, height: 24)
                    } else {
                        Text(Loc.Subscription.Paywall.startProSubscription)
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .multilineTextAlignment(.center)
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
                Text(Loc.Subscription.Paywall.restoreSubscription)
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            .disabled(isLoading)
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 20)
    }
    
    // MARK: - Registration Benefits Section
    
    private var registrationBenefitsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundStyle(.accent)
                Text(Loc.Auth.registrationBenefits)
                    .font(.headline)
                    .fontWeight(.medium)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 8) {
                BenefitRow(
                    icon: "candybarphone",
                    text: Loc.Auth.accessSubscriptionAllDevices
                )
                BenefitRow(
                    icon: "arrow.trianglehead.2.clockwise.rotate.90",
                    text: Loc.Auth.syncProgressCrossPlatform
                )
                BenefitRow(
                    icon: "person.3.fill",
                    text: Loc.Onboarding.shareDictionaries
                )
            }
            
            Text(Loc.Auth.registerAnytimeFromSettings)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.leading)
        }
        .padding(16)
        .background(Color.green.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.green.opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - Social Proof Section

    private var socialProofSection: some View {
        VStack(spacing: 16) {
            Text(Loc.Subscription.Paywall.trustedByLearnersWorldwide)
                .font(.headline)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)

            HStack(spacing: 20) {
                SocialProofCard(
                    number: "4.8",
                    label: Loc.Subscription.Paywall.appStoreRating
                )

                SocialProofCard(
                    number: "5K+",
                    label: Loc.Subscription.Paywall.activeUsers
                )

                SocialProofCard(
                    number: "100K+",
                    label: Loc.Subscription.Paywall.wordsAdded
                )
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 20)
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

    private func restorePurchases() async {
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
    
    // MARK: - Helper Functions
    
    private func getAchievementIcon(for achievement: String) -> String {
        if achievement.contains("words") {
            return "book.fill"
        } else if achievement.contains("academic") {
            return "graduationcap.fill"
        } else if achievement.contains("professional") || achievement.contains("business") {
            return "briefcase.fill"
        } else if achievement.contains("travel") {
            return "airplane"
        } else if achievement.contains("tech") {
            return "laptopcomputer"
        } else {
            return "star.fill"
        }
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
        .multilineTextAlignment(.center)
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
                    .lineLimit(3)
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
            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(plan.displayName)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    if plan.period == .year {
                        TagView(text: Loc.Subscription.Paywall.bestValue)
                    }

                    if let pricePerMonth = plan.pricePerMonth {
                        Text(pricePerMonth + "/" + Loc.Subscription.Period.month)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
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
        .frame(maxWidth: .infinity, alignment: .center)
        .multilineTextAlignment(.center)
    }
}

struct BenefitRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.accent)
                .frame(width: 16)
            
            Text(text)
                .font(.caption)
                .foregroundStyle(.primary)
            
            Spacer()
        }
    }
}

struct PersonalizedAchievementCard: View {
    let achievement: String
    let icon: String
    let delay: Double
    @State private var isVisible = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.purple, Color.purple.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 28)

            Text(achievement)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.leading)

            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.purple.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.purple.opacity(0.3), lineWidth: 1)
                )
        )
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 20)
        .onAppear {
            withAnimation(.easeOut(duration: 0.6).delay(delay)) {
                isVisible = true
            }
        }
    }
}

#Preview {
    AdvancedPaywallView()
}
