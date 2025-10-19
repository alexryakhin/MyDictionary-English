//
//  OnboardingLoadingView.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import SwiftUI

struct OnboardingLoadingView: View {
    
    let message: String
    
    init(message: String = Loc.Onboarding.loadingFromIcloud) {
        self.message = message
    }
    
    var body: some View {
        VStack(spacing: 24) {
            ProgressView()
                .progressViewStyle(.circular)
                .scaleEffect(1.5)
                .tint(.accent)
            
            Text(message)
                .font(.title3)
                .foregroundColor(.secondaryLabel)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.systemGroupedBackground)
    }
}

#Preview {
    OnboardingLoadingView()
}

