//
//  OnboardingView.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/10/25.
//

import SwiftUI

struct OnboardingView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @AppStorage(UDKeys.hasCompletedOnboarding) private var hasCompletedOnboarding: Bool = false

    @State private var currentStep = 0
    @State private var animateContent = false
    @State private var animateBackground = false
    @State private var showPulse = false
    
    private let totalSteps = 4
    
    var body: some View {
        ZStack {
            // Animated background
            backgroundGradient
                .ignoresSafeArea()
                .scaleEffect(animateBackground ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 8).repeatForever(autoreverses: true), value: animateBackground)
            
            VStack(spacing: 0) {
                // Progress indicator
                progressIndicator
                    .padding(.top, 60)
                    .padding(.horizontal, 24)
                
                // Main content
                TabView(selection: $currentStep) {
                    welcomeStep
                        .tag(0)
                    
                    featuresStep
                        .tag(1)
                    
                    personalizationStep
                        .tag(2)
                    
                    getStartedStep
                        .tag(3)
                }
                .animation(.easeInOut(duration: 0.5), value: currentStep)
                #if os(iOS)
                .tabViewStyle(.page(indexDisplayMode: .never))
                #endif

                // Navigation buttons
                navigationButtons
                    .padding(vertical: 12, horizontal: 16)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0)) {
                animateContent = true
                animateBackground = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                    showPulse = true
                }
            }
        }
    }
    
    // MARK: - Background
    
    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Color.accentColor.opacity(0.1),
                Color.accentColor.opacity(0.05),
                Color.systemBackground
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // MARK: - Progress Indicator
    
    private var progressIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalSteps, id: \.self) { step in
                Circle()
                    .fill(step <= currentStep ? Color.accentColor : Color.accentColor.opacity(0.3))
                    .frame(width: 8, height: 8)
                    .scaleEffect(step == currentStep ? 1.2 : 1.0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: currentStep)
            }
        }
        .opacity(animateContent ? 1 : 0)
        .offset(y: animateContent ? 0 : 20)
    }
    
    // MARK: - Welcome Step
    
    private var welcomeStep: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // App icon with animation
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.1))
                    .frame(width: 120, height: 120)
                    .scaleEffect(showPulse ? 1.1 : 1.0)
                
                Image(systemName: "textformat")
                    .font(.system(size: 50, weight: .medium))
                    .foregroundStyle(Color.accentColor)
                    .scaleEffect(animateContent ? 1.0 : 0.5)
                    .rotationEffect(.degrees(animateContent ? 0 : -180))
            }
            .animation(.spring(response: 1.0, dampingFraction: 0.8), value: animateContent)

            Spacer()

            VStack(spacing: 16) {
                Text(Loc.Onboarding.welcomeTo.localized)
                    .font(.title2)
                    .foregroundStyle(.secondary)
                    .opacity(animateContent ? 1 : 0)
                    .offset(y: animateContent ? 0 : 20)
                
                Text(Loc.Onboarding.myDictionary.localized)
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                    .opacity(animateContent ? 1 : 0)
                    .offset(y: animateContent ? 0 : 20)
                
                Text(Loc.Onboarding.personalVocabularyCompanion.localized)
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .opacity(animateContent ? 1 : 0)
                    .offset(y: animateContent ? 0 : 20)
            }
            .multilineTextAlignment(.center)
            .animation(.easeInOut(duration: 0.8).delay(0.3), value: animateContent)
            
            Spacer()
            Spacer()
        }
        .padding(.horizontal, 32)
    }
    
    // MARK: - Features Step
    
    private var featuresStep: some View {
        VStack(spacing: 0) {
            Spacer()
            
            Text(Loc.Onboarding.buildYourVocabulary.localized)
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)
                .opacity(animateContent ? 1 : 0)
                .offset(y: animateContent ? 0 : 20)

            Spacer()

            VStack(spacing: 16) {
                ForEach(Array(onboardingFeatures.enumerated()), id: \.offset) { index, feature in
                    FeatureCard(
                        icon: feature.icon,
                        title: feature.title,
                        description: feature.description,
                        delay: Double(index) * 0.2
                    )
                    .opacity(animateContent ? 1 : 0)
                    .offset(x: animateContent ? 0 : -50)
                }
            }
            .animation(.easeInOut(duration: 0.8).delay(0.4), value: animateContent)
            
            Spacer()
        }
        .padding(.horizontal, 16)
    }
    
    // MARK: - Personalization Step
    
    private var personalizationStep: some View {
        VStack(spacing: 0) {
            Spacer()
            
            Text(Loc.Onboarding.personalizedLearning.localized)
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)
                .opacity(animateContent ? 1 : 0)
                .offset(y: animateContent ? 0 : 20)

            Spacer()

            VStack(spacing: 16) {
                PersonalizationCard(
                    icon: "brain.head.profile",
                    title: Loc.Onboarding.smartQuizzes.localized,
                    description: Loc.Onboarding.smartQuizzesDescription.localized,
                    color: .blue
                )
                .opacity(animateContent ? 1 : 0)
                .offset(x: animateContent ? 0 : -50)
                
                PersonalizationCard(
                    icon: "chart.line.uptrend.xyaxis",
                    title: Loc.Onboarding.progressTracking.localized,
                    description: Loc.Onboarding.progressTrackingDescription.localized,
                    color: .accent
                )
                .opacity(animateContent ? 1 : 0)
                .offset(x: animateContent ? 0 : 50)
                
                PersonalizationCard(
                    icon: "person.wave.2.fill",
                    title: Loc.Onboarding.naturalVoices.localized,
                    description: Loc.Onboarding.naturalVoicesDescription.localized,
                    color: .orange
                )
                .opacity(animateContent ? 1 : 0)
                .offset(x: animateContent ? 0 : -50)
                
                PersonalizationCard(
                    icon: "person.2.fill",
                    title: Loc.Onboarding.collaborativeLearning.localized,
                    description: Loc.Onboarding.collaborativeLearningDescription.localized,
                    color: .purple
                )
                .opacity(animateContent ? 1 : 0)
                .offset(x: animateContent ? 0 : 50)
            }
            .animation(.easeInOut(duration: 0.8).delay(0.4), value: animateContent)
            
            Spacer()
        }
        .padding(.horizontal, 16)
    }
    
    // MARK: - Get Started Step
    
    private var getStartedStep: some View {
        VStack(spacing: 0) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.1))
                    .frame(width: 140, height: 140)
                    .scaleEffect(showPulse ? 1.2 : 1.0)
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(Color.accentColor)
                    .scaleEffect(animateContent ? 1.0 : 0.5)
            }
            .animation(.spring(response: 1.0, dampingFraction: 0.8), value: animateContent)

            Spacer()

            VStack(spacing: 16) {
                Text(Loc.Onboarding.youreAllSet.localized)
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    .foregroundStyle(.primary)
                    .opacity(animateContent ? 1 : 0)
                    .offset(y: animateContent ? 0 : 20)
                
                Text(Loc.Onboarding.startBuildingVocabulary.localized)
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .opacity(animateContent ? 1 : 0)
                    .offset(y: animateContent ? 0 : 20)
            }
            .multilineTextAlignment(.center)
            .animation(.easeInOut(duration: 0.8).delay(0.3), value: animateContent)
            
            Spacer()
        }
        .padding(.horizontal, 32)
    }
    
    // MARK: - Navigation Buttons
    
    private var navigationButtons: some View {
        HStack(spacing: 16) {
            if currentStep > 0 {
                ActionButton(Loc.Onboarding.back.localized) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        currentStep -= 1
                    }
                }
            }
            
            ActionButton(
                currentStep == totalSteps - 1 ? Loc.Onboarding.getStarted.localized : Loc.Onboarding.next.localized,
                style: .borderedProminent
            ) {
                if currentStep < totalSteps - 1 {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        currentStep += 1
                    }
                } else {
                    hasCompletedOnboarding = true
                    dismiss()
                }
            }
        }
        .animation(.easeInOut(duration: 0.8).delay(0.6), value: animateContent)
    }
    
    // MARK: - Data Models
    
    private struct OnboardingFeature {
        let icon: String
        let title: String
        let description: String
    }
    
    private var onboardingFeatures: [OnboardingFeature] {
        [
            OnboardingFeature(
                icon: "text.justify",
                title: Loc.Onboarding.personalWordList.localized,
                description: Loc.Onboarding.personalWordListDescription.localized
            ),
            OnboardingFeature(
                icon: "network",
                title: Loc.Onboarding.findDefinitions.localized,
                description: Loc.Onboarding.findDefinitionsDescription.localized
            ),
            OnboardingFeature(
                icon: "scroll",
                title: Loc.Onboarding.collectIdioms.localized,
                description: Loc.Onboarding.collectIdiomsDescription.localized
            )
        ]
    }
}


extension OnboardingView {

    // MARK: - Feature Card Component

    struct FeatureCard: View {
        let icon: String
        let title: String
        let description: String
        let delay: Double

        @State private var animate = false

        var body: some View {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.accentColor.opacity(0.1))
                        .frame(width: 56, height: 56)

                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundStyle(Color.accentColor)
                }
                .scaleEffect(animate ? 1.0 : 0.8)
                .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(delay), value: animate)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Text(description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.systemBackground)
                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
            )
            .onAppear {
                withAnimation(.easeInOut(duration: 0.6).delay(delay)) {
                    animate = true
                }
            }
        }
    }

    // MARK: - Personalization Card Component

    struct PersonalizationCard: View {
        let icon: String
        let title: String
        let description: String
        let color: Color

        @State private var animate = false

        var body: some View {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(color.opacity(0.1))
                        .frame(width: 56, height: 56)

                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundStyle(color)
                }
                .scaleEffect(animate ? 1.0 : 0.8)
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: animate)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Text(description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.systemBackground)
                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
            )
            .onAppear {
                withAnimation(.easeInOut(duration: 0.6)) {
                    animate = true
                }
            }
        }
    }
}
