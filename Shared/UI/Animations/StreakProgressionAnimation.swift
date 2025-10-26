//
//  StreakProgressionAnimation.swift
//  My Dictionary
//
//  Created by Assistant on 8/25/25.
//

import SwiftUI

struct StreakProgressionAnimation: View {
    @Binding var isActive: Bool
    @State private var flameScale: CGFloat = 0.5
    @State private var numberScale: CGFloat = 0.5
    @State private var opacity: Double = 0.0
    @State private var animatingValue: Int = 0

    let targetStreak: Int

    private let animationDuration = 2.0
    private let fadeDuration = 1.0

    var body: some View {
        ZStack {
            if isActive {
                VStack(spacing: 20) {
                    // Flame icon with scale animation
                    Image(systemName: "flame.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.orange, .red],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .scaleEffect(flameScale)

                    // Streak number
                    VStack(spacing: 8) {
                        Text("\(animatingValue)")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundStyle(.primary)
                            .scaleEffect(numberScale)

                        Text(Loc.Analytics.dayStreak)
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(32)
                .glassBackgroundEffectIfAvailableWithBackup(.tint(.orange.opacity(0.2)))
                .opacity(opacity)
                .task {
                    await handleAnimationSequence()
                }
            }
        }
        .allowsHitTesting(false)
    }

    private func handleAnimationSequence() async {
        // Initial animation - flame and number pop in
        HapticManager.shared.triggerImpact(style: .light)
        
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            flameScale = 1.2
            numberScale = 1.2
            opacity = 1.0
        }

        // Bounce back
        try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds

        withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
            flameScale = 1.0
            numberScale = 1.0
        }

        // Count up the streak number
        try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds

        let duration = animationDuration - 0.5 // Account for initial animations
        let steps = abs(targetStreak - 0)
        let stepDuration = duration / Double(max(steps, 1))

        for i in 0...steps {
            animatingValue = min(i, targetStreak)
            // Subtle haptic feedback during counting
            if i > 0 && i % 3 == 0 {
                HapticManager.shared.triggerImpact(style: .soft)
            }
            try? await Task.sleep(nanoseconds: UInt64(stepDuration * 1_000_000_000))
        }

        // Final pulse with success haptic
        HapticManager.shared.triggerNotification(type: .success)
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) {
            flameScale = 1.15
            numberScale = 1.15
        }

        try? await Task.sleep(nanoseconds: 150_000_000) // 0.15 seconds

        withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) {
            flameScale = 1.0
            numberScale = 1.0
        }

        // Fade out
        try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds

        withAnimation(.easeOut(duration: fadeDuration)) {
            opacity = 0.0
        }

        // Wait for fade to complete
        try? await Task.sleep(nanoseconds: UInt64(fadeDuration * 1_000_000_000))

        // Reset
        isActive = false
    }
}

#Preview {
    ZStack {
        Color.systemGroupedBackground.ignoresSafeArea()

        StreakProgressionAnimation(isActive: .constant(true), targetStreak: 8)
    }
}
