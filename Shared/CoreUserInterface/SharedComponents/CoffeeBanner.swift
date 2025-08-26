//
//  CoffeeBanner.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/10/25.
//

import SwiftUI

struct CoffeeBanner: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.openURL) var openURL

    @StateObject private var sessionManager: SessionManager = .shared
    @State private var animate = false
    @State private var showPulse = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Header with coffee icon and message
            VStack(spacing: 12) {
                HStack(alignment: .top) {
                    ZStack {
                        Circle()
                            .fill(Color.orange.opacity(0.2))
                            .frame(width: 60, height: 60)
                            .scaleEffect(showPulse ? 1.1 : 1.0)
                        
                        Image(systemName: "cup.and.saucer.fill")
                            .font(.system(size: 28, weight: .medium))
                            .foregroundStyle(Color.orange)
                            .scaleEffect(animate ? 1.0 : 0.8)
                            .rotationEffect(.degrees(animate ? 0 : -10))
                    }
                    .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: showPulse)
                    .animation(.spring(response: 0.8, dampingFraction: 0.6), value: animate)
                    
                    Spacer()
                    
                    Button {
                        sessionManager.markCoffeeBannerDismissed()
                        AnalyticsService.shared.logEvent(.coffeeBannerDismissed)
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                }
                
                VStack(spacing: 8) {
                    Text(Loc.Coffee.enjoyingTheApp)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text(Loc.Coffee.helpfulLearningJourney)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .multilineTextAlignment(.leading)
                }
            }

            Spacer()

            // Action buttons
            VStack(spacing: 12) {
                ActionButton(Loc.Coffee.buyMeACoffee, systemImage: "cup.and.saucer.fill", color: .orange, style: .borderedProminent) {
                    openURL(GlobalConstant.buyMeACoffeeUrl)
                    sessionManager.markCoffeeBannerShown()
                    AnalyticsService.shared.logEvent(.coffeeBannerTapped)
                    dismiss()
                }
                ActionButton(Loc.Coffee.maybeLater) {
                    sessionManager.markCoffeeBannerDismissed()
                    AnalyticsService.shared.logEvent(.coffeeBannerDismissed)
                    dismiss()
                }
            }
        }
        .padding(20)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8)) {
                animate = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                    showPulse = true
                }
            }
        }
    }
}

#Preview {
    CoffeeBanner()
        .padding()
}
