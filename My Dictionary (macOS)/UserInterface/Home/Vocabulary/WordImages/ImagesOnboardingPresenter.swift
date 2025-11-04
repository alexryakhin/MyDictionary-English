//
//  ImagesOnboardingPresenter.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 1/9/25.
//

import SwiftUI

struct ImagesOnboardingPresenter: ViewModifier {
    @Binding var isPresented: Bool
    let onCompleted: (() -> Void)?
    @StateObject private var subscriptionService = SubscriptionService.shared
    
    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $isPresented) {
                ImagesOnboardingView(isPresented: $isPresented, onCompleted: { 
                    // When onboarding is completed (either by skipping or clicking "Get Started")
                    // Check if user is pro, and if so, mark onboarding as shown
                    if subscriptionService.isProUser {
                        UDService.imageOnboardingShown = true
                    }
                    onCompleted?()
                })
            }
    }
}

extension View {
    func imagesOnboarding(isPresented: Binding<Bool>, onCompleted: (() -> Void)? = nil) -> some View {
        modifier(ImagesOnboardingPresenter(isPresented: isPresented, onCompleted: onCompleted))
    }
}

// MARK: - Helper for determining if onboarding should be shown
struct ImagesOnboardingHelper {
    static func shouldShowOnboarding() -> Bool {
        // If user is not pro, always show onboarding (no state saved)
        if !SubscriptionService.shared.isProUser {
            return true
        }
        
        // If user is pro, only show if they haven't seen it before
        return !UDService.imageOnboardingShown
    }
}
