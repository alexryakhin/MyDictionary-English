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
                Text("Welcome to")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                    .opacity(animateContent ? 1 : 0)
                    .offset(y: animateContent ? 0 : 20)
                
                Text("My Dictionary")
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                    .opacity(animateContent ? 1 : 0)
                    .offset(y: animateContent ? 0 : 20)
                
                Text("Your personal vocabulary companion")
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
            
            Text("Build Your Vocabulary")
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
            
            Text("Personalized Learning")
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)
                .opacity(animateContent ? 1 : 0)
                .offset(y: animateContent ? 0 : 20)

            Spacer()

            VStack(spacing: 16) {
                PersonalizationCard(
                    icon: "brain.head.profile",
                    title: "Smart Quizzes",
                    description: "Adaptive quizzes that learn from your progress",
                    color: .blue
                )
                .opacity(animateContent ? 1 : 0)
                .offset(x: animateContent ? 0 : -50)
                
                PersonalizationCard(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Progress Tracking",
                    description: "Visual insights into your vocabulary growth",
                    color: .accent
                )
                .opacity(animateContent ? 1 : 0)
                .offset(x: animateContent ? 0 : 50)
                
                PersonalizationCard(
                    icon: "person.2.fill",
                    title: "Collaborative Learning",
                    description: "Share dictionaries with friends and family",
                    color: .purple
                )
                .opacity(animateContent ? 1 : 0)
                .offset(x: animateContent ? 0 : -50)
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
                Text("You're All Set!")
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    .foregroundStyle(.primary)
                    .opacity(animateContent ? 1 : 0)
                    .offset(y: animateContent ? 0 : 20)
                
                Text("Start building your vocabulary today and watch your language skills grow.")
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
                ActionButton("Back") {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        currentStep -= 1
                    }
                }
            }
            
            ActionButton(
                currentStep == totalSteps - 1 ? "Get Started" : "Next",
                style: .borderedProminent
            ) {
                if currentStep < totalSteps - 1 {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        currentStep += 1
                    }
                } else {
                    // Mark onboarding as completed in UserDefaults
                    UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
                    
                    // Send onboarding completed notification
                    NotificationCenter.default.post(name: .onboardingCompleted, object: nil)
                    
                    dismiss()
                }
            }
        }
        .opacity(animateContent ? 1 : 0)
        .offset(y: animateContent ? 0 : 20)
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
                title: "Personal Word List",
                description: "Create and organize your own vocabulary collections with custom definitions and examples"
            ),
            OnboardingFeature(
                icon: "network",
                title: "Find Definitions",
                description: "Get comprehensive definitions with multiple meanings and contexts"
            ),
            OnboardingFeature(
                icon: "scroll",
                title: "Collect Idioms",
                description: "Learn and practice idioms and expressions from around the world"
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

#Preview {
    OnboardingView()
}
