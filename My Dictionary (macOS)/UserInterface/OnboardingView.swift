//
//  OnboardingView.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/10/25.
//

import SwiftUI

struct OnboardingView: View {
    let isNewUser: Bool
    
    init() {
        // Determine if user is new based on whether they've completed onboarding before
        // If they have a partial profile but haven't completed, they'll resume
        self.isNewUser = !UDService.hasCompletedOnboarding
    }
    
    var body: some View {
        OnboardingContainerView(isNewUser: isNewUser)
    }
}
