//
//  OnboardingPaywallView.swift
//  My Dictionary
//
//  Created by Alexander Riakhin on 10/17/25.
//

import SwiftUI

extension OnboardingFlow {
    struct PaywallView: View {
        @Environment(\.openURL) var openURL
        @ObservedObject var viewModel: OnboardingFlow.ViewModel
        @StateObject private var subscriptionService = SubscriptionService.shared

        @State private var animateHeader = false
        @State private var animateFeatures = false
        @State private var animateSocialProof = false
        @State private var animateButton = false
        @State private var showPulse = false
        @State private var selectedPlan: SubscriptionPlan?
        @State private var safariURL: URL?

        // Top 3 most compelling reviews for static display
        private let topReviews = [
            UserReview(id: 2, name: "Branwiches", country: "United States", rating: 5, text: "I've been looking for something basic and simple like this for over a YEAR. This little My Dictionary app is SO easy to use and EXACTLY what I was looking for. I also LOVE that it lets you enter in your own examples!!"),
            UserReview(id: 5, name: "_lynn！", country: "United States", rating: 5, text: "I'm looking for an app which can make my own quizzes for months. And I'm so happy to find the idioms section!! This little app definitely has everything for building your own dictionary! Best dictionary app ever."),
            UserReview(id: 1, name: "Hydrangia", country: "United Kingdom", rating: 5, text: "I'm very pleased with this app. I can now key in words that I'm not familiar with and test myself with the quiz. So far everything in the app is working well and I'm enjoying it. It's great that it syncs as well as I have it on another device.")
        ]

        private var perfectForGoalsText: String {
            let language = viewModel.studyLanguages.first?.language.displayName ?? "Language"
            return Loc.Onboarding.Paywall.perfectForYourGoals(language)
        }

        private var featuresTailoredText: String {
            let userType = viewModel.selectedUserType?.rawValue ?? "learning"
            let language = viewModel.studyLanguages.first?.language.displayName ?? "your target language"
            return Loc.Onboarding.Paywall.featuresTailoredToJourney(userType, language)
        }

        private var personalizedTitle: String {
            if !viewModel.userName.isEmpty {
                return Loc.Onboarding.Paywall.personalizedTitle(viewModel.userName)
            }
            return Loc.Onboarding.Paywall.personalizedTitle("").replacingOccurrences(of: ", ", with: "")
        }

        private var personalizedSubtitle: String {
            let goals = viewModel.selectedGoals
            let userType = viewModel.selectedUserType?.rawValue ?? "learner"
            let studyLanguages = viewModel.studyLanguages

            // Get the primary study language
            let primaryLanguage = studyLanguages.first?.language.displayName ?? "your target language"

            if goals.contains(.study) {
                return Loc.Onboarding.Paywall.personalizedSubtitleStudy(primaryLanguage)
            } else if goals.contains(.work) {
                return Loc.Onboarding.Paywall.personalizedSubtitleWork(primaryLanguage)
            } else if goals.contains(.travel) {
                return Loc.Onboarding.Paywall.personalizedSubtitleTravel(primaryLanguage)
            } else if goals.contains(.business) {
                return Loc.Onboarding.Paywall.personalizedSubtitleBusiness(primaryLanguage)
            } else {
                return Loc.Onboarding.Paywall.personalizedSubtitleDefault(userType, primaryLanguage)
            }
        }

        private var personalizedAchievements: [String] {
            var achievements: [String] = []
            let studyLanguages = viewModel.studyLanguages
            let primaryLanguage = studyLanguages.first?.language.displayName ?? "your target language"

            // Based on weekly goal
            let dailyGoal = viewModel.weeklyWordGoal / 7
            achievements.append(Loc.Onboarding.Paywall.achievementMasterWords(dailyGoal * 7, primaryLanguage))

            // Based on user type and goals
            if viewModel.selectedGoals.contains(.study) {
                achievements.append(Loc.Onboarding.Paywall.achievementAcademicWriting(primaryLanguage))
            }
            if viewModel.selectedGoals.contains(.work) {
                achievements.append(Loc.Onboarding.Paywall.achievementProfessionalCommunication(primaryLanguage))
            }
            if viewModel.selectedGoals.contains(.travel) {
                achievements.append(Loc.Onboarding.Paywall.achievementTravelConfidence(primaryLanguage))
            }
            if viewModel.selectedGoals.contains(.business) {
                achievements.append(Loc.Onboarding.Paywall.achievementBusinessCommunication(primaryLanguage))
            }

            // Based on interests
            if viewModel.selectedInterests.contains(.technology) {
                achievements.append(Loc.Onboarding.Paywall.achievementTechVocabulary(primaryLanguage))
            }
            if viewModel.selectedInterests.contains(.business) {
                achievements.append(Loc.Onboarding.Paywall.achievementBusinessContexts(primaryLanguage))
            }

            return achievements
        }

        private var personalizedFeatures: [SubscriptionFeature] {
            var features: [SubscriptionFeature] = []

            // Always include core features (top 3)
            features.append(.aiDefinitions)
            features.append(.aiQuizzes)
            features.append(.images)

            // Add 1 more feature based on user goals/interests
            if viewModel.selectedGoals.contains(.study) {
                features.append(.advancedAnalytics)
            } else if viewModel.selectedGoals.contains(.work) {
                features.append(.unlimitedExport)
            } else if viewModel.selectedGoals.contains(.travel) {
                features.append(.premiumTTS)
            } else if viewModel.selectedInterests.contains(.technology) {
                features.append(.wordCollections)
            } else if viewModel.selectedInterests.contains(.business) {
                features.append(.createSharedDictionaries)
            }

            return features
        }

        private var buttonText: String {
            guard let selectedPlan else {
                return Loc.Onboarding.Paywall.startMyFreeTrialNow
            }

            if selectedPlan.period == .year {
                return Loc.Onboarding.Paywall.startFreeTrialSave("37%")
            } else {
                return Loc.Onboarding.Paywall.startMyFreeTrialNow
            }
        }

        var body: some View {
            ScrollView(.vertical) {
                VStack(spacing: 0) {
                    // Hero section with gradient background
                    heroSection

                    // Features with animations
                    featuresSection
                        .opacity(animateFeatures ? 1 : 0)
                        .offset(y: animateFeatures ? 0 : 50)

                    // Social proof
                    socialProofSection
                        .opacity(animateSocialProof ? 1 : 0)
                        .offset(y: animateSocialProof ? 0 : 30)

                    // Plans selection
                    plansSection
                        .opacity(animateSocialProof ? 1 : 0)
                        .offset(y: animateSocialProof ? 0 : 30)
                }
            }
            .withGradientBackground()
            .safeAreaBarIfAvailable {
                VStack(spacing: 12) {
                    if let selectedPlan {
                        Text(Loc.Subscription.Paywall.planAutoRenews(selectedPlan.price, selectedPlan.period.displayName))
                            .foregroundStyle(.secondary)
                            .font(.caption)
                            .multilineTextAlignment(.center)
                    }

                    // Subscribe button - shows "Try for Free" if trial is available
                    AsyncActionButton(
                        buttonText,
                        systemImage: "book.fill",
                        style: .borderedProminent
                    ) {
                        try await purchaseSelectedPlan()
                    }

                    // Restore button
                    AsyncActionButton(
                        Loc.Subscription.Paywall.restoreSubscription,
                        style: .bordered
                    ) {
                        try await subscriptionService.restorePurchases()
                    }
                }
                .scaleEffect(animateButton ? 1.0 : 0.95)
                .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(1.2), value: animateButton)
                .padding(vertical: 12, horizontal: 16)
                .materialBackgroundIfNoGlassAvailable()
            }
            .safari(url: $safariURL)
            .onAppear {
                startAnimations()
                // Set default plan if none selected
                if selectedPlan == nil {
                    selectedPlan = subscriptionService.defaultPlan
                }
                
                // Pre-generate AI paywall content if not already done
                if !PaywallContentService.shared.hasGenerated {
                    Task {
                        await PaywallContentService.shared.generatePaywallContent()
                    }
                }
            }
        }

        // MARK: - Hero Section

        private var heroSection: some View {
            VStack(spacing: 24) {
                Spacer()
                    .frame(height: 20)

                // Animated illustration
                Image(.illustrationPremium)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 250)
                    .scaleEffect(animateHeader ? 1.0 : 0.5)
                    .animation(.spring(response: 1.0, dampingFraction: 0.8), value: animateHeader)

                // Personalized urgency
                Label(
                    Loc.Onboarding.Paywall.personalizedForYou,
                    systemImage: "person.crop.circle.badge.checkmark"
                )
                .foregroundStyle(.accent)
                .padding(vertical: 12, horizontal: 16)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.accentColor.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.accentColor.opacity(0.3), lineWidth: 1)
                        )
                )

                Text(personalizedTitle)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                Text(personalizedSubtitle)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)

                // Personalized achievement preview
                HStack(spacing: 16) {
                    Spacer()
                    VStack(spacing: 4) {
                        Text("7")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundStyle(.green)
                        Text(Loc.Onboarding.Paywall.days)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)

                    VStack(spacing: 4) {
                        Text(viewModel.weeklyWordGoal.formatted())
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundStyle(.blue)
                        Text(Loc.Onboarding.Paywall.wordsGoal)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    VStack(spacing: 4) {
                        Text(viewModel.studyLanguages.count.formatted())
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundStyle(.purple)
                        Text(Loc.Plurals.Onboarding.languagesCountWn(viewModel.studyLanguages.count))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    Spacer()
                }
                .padding(.horizontal, 16)
            }
            .padding(.bottom, 30)
        }

        // MARK: - Features Section

        private var featuresSection: some View {
            VStack(spacing: 20) {
                VStack(spacing: 8) {
                    Text(perfectForGoalsText)
                        .font(.title2)
                        .fontWeight(.semibold)

                    Text(featuresTailoredText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 16)

                VStack(spacing: 12) {
                    ForEach(0..<personalizedFeatures.count, id: \.self) { index in
                        let feature = personalizedFeatures[index]
                        PersonalizedFeatureCard(
                            feature: feature,
                            delay: Double(index) * 0.1,
                            isPriority: index < 3
                        )
                    }
                }
                .padding(.horizontal, 16)
            }
            .padding(.vertical, 20)
        }

        // MARK: - Reviews Section

        private var socialProofSection: some View {
            VStack(spacing: 20) {
                VStack(spacing: 8) {
                    Text(Loc.Onboarding.Paywall.whatOurUsersSay)
                        .font(.title2)
                        .fontWeight(.semibold)

                    Text(Loc.Onboarding.Paywall.joinThousandsSatisfied)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                // Static display of top 3 reviews
                VStack(spacing: 12) {
                    ForEach(topReviews, id: \.id) { review in
                        ReviewCard(review: review)
                    }
                }
                .padding(.horizontal, 16)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 20)
        }

        // MARK: - Plans Section

        private var plansSection: some View {
            VStack(alignment: .center, spacing: 20) {
                VStack(alignment: .center, spacing: 8) {
                    Text(Loc.Onboarding.Paywall.chooseYourPlan)
                        .font(.title2)
                        .fontWeight(.semibold)

                    Text(Loc.Onboarding.Paywall.startFreeUpgradeWhenNeeded)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)

                VStack(spacing: 12) {
                    ForEach(subscriptionService.availablePlans, id: \.id) { plan in
                        PlanCard(
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
                    .foregroundStyle(.accent)
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
                    .foregroundStyle(.accent)
                }
                .font(.caption)
                .frame(maxWidth: .infinity, alignment: .center)
            }
            .padding(.vertical, 20)
        }

        // MARK: - Animation Methods

        private func startAnimations() {
            withAnimation(.easeOut(duration: 0.6).delay(0.1)) {
                animateHeader = true
            }

            withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
                animateFeatures = true
            }

            withAnimation(.easeOut(duration: 0.6).delay(0.3)) {
                animateSocialProof = true
            }

            withAnimation(.easeOut(duration: 0.6).delay(0.4)) {
                animateButton = true
            }
        }

        // MARK: - Helper Methods

        private func getAchievementIcon(for index: Int) -> String {
            let icons = ["brain.head.profile", "chart.line.uptrend.xyaxis", "book.fill", "person.2.fill", "star.fill", "trophy.fill"]
            return icons[index % icons.count]
        }

        private func purchaseSelectedPlan() async throws {
            guard let plan = selectedPlan else {
                // No plan selected, proceed to success (user skipped paywall)
                viewModel.navigate(to: .success)
                return
            }

            try await subscriptionService.purchasePlan(plan)
            viewModel.navigate(to: .success)
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

    struct PersonalizedFeatureCard: View {
        let feature: SubscriptionFeature
        let delay: Double
        let isPriority: Bool
        @State private var isVisible = false

        var body: some View {
            HStack(spacing: 12) {
                ZStack {
                    if isPriority {
                        Circle()
                            .fill(Color.accentColor.opacity(0.2))
                            .frame(width: 36, height: 36)

                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundStyle(.accent)
                            .offset(x: 12, y: -12)
                    }

                    Image(systemName: feature.iconName)
                        .font(.title2)
                        .foregroundStyle(
                            LinearGradient(
                                colors: isPriority ?
                                [Color.accentColor, Color.accentColor.opacity(0.7)] :
                                    [Color.secondary, Color.secondary.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 28)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(feature.displayName)
                            .font(.subheadline)
                            .fontWeight(.medium)

                        if isPriority {
                            Text(Loc.Onboarding.Paywall.recommended)
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.accentColor)
                                )
                        }
                    }

                    Text(feature.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                }

                Spacer()
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isPriority ? Color.accentColor.opacity(0.05) : Color.secondarySystemGroupedBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isPriority ? Color.accentColor.opacity(0.3) : Color.clear, lineWidth: 1)
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

    struct AchievementRow: View {
        let icon: String
        let text: String

        var body: some View {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(.accent)
                    .frame(width: 24)

                Text(text)
                    .font(.body)
                    .foregroundStyle(.primary)

                Spacer()

                Image(systemName: "checkmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.green)
            }
        }
    }

    struct UserReview {
        let id: Int
        let name: String
        let country: String
        let rating: Int
        let text: String
    }

    struct ReviewCard: View {
        let review: UserReview

        var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(review.name)
                            .font(.headline)
                            .fontWeight(.semibold)

                        Text(review.country)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    HStack(spacing: 2) {
                        ForEach(0..<review.rating, id: \.self) { _ in
                            Image(systemName: "star.fill")
                                .font(.caption)
                                .foregroundStyle(.yellow)
                        }
                    }
                }

                Text(review.text)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .lineLimit(4)
                    .multilineTextAlignment(.leading)
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.secondarySystemGroupedBackground)
                    .shadow(color: .label.opacity(0.08), radius: 8, x: 0, y: 4)
            )
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

    // MARK: - Premium Feature Row (Legacy)

    struct PremiumFeatureRow: View {
        let icon: String
        let text: String
        let color: Color
        let delay: Double
        let show: Bool

        var body: some View {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(color.opacity(0.15))
                        .frame(width: 56, height: 56)

                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundStyle(color)
                }

                Text(text)
                    .font(.body)
                    .foregroundStyle(.primary)

                Spacer()
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.secondarySystemGroupedBackground)
                    .shadow(color: .label.opacity(0.08), radius: 10, x: 0, y: 5)
            )
            .opacity(show ? 1 : 0)
            .offset(x: show ? 0 : -50)
            .animation(.easeInOut(duration: 0.6).delay(delay), value: show)
        }
    }
}
