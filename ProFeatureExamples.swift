//
//  ProFeatureExamples.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//
//  Examples of Pro feature placeholders with aurora background
//

import SwiftUI

// MARK: - Example 1: Google Sync Placeholder

struct GoogleSyncPlaceholder: View {
    @StateObject private var paywallService = PaywallService.shared
    
    var body: some View {
        ZStack {
            AuroraBackground()
            
            VStack(spacing: 32) {
                Spacer()
                
                // Icon and title
                VStack(spacing: 16) {
                    Image(systemName: "icloud.and.arrow.up")
                        .font(.system(size: 80))
                        .foregroundStyle(.white)
                    
                    Text("Google Sync")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                }
                
                // Description
                VStack(spacing: 12) {
                    Text("Sync your words across all devices")
                        .font(.title3)
                        .foregroundStyle(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                    
                    Text("Keep your vocabulary in sync with Google Drive")
                        .font(.body)
                        .foregroundStyle(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 32)
                
                Spacer()
                
                // Action buttons
                VStack(spacing: 16) {
                    Button {
                        paywallService.presentPaywall(for: .googleSync) { didSubscribe in
                            if didSubscribe {
                                print("User subscribed for Google Sync")
                            }
                        }
                    } label: {
                        Text("Upgrade to Pro")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal, 32)
                    
                    Button("Continue with iCloud") {
                        // Handle iCloud fallback
                    }
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.6))
                }
                
                Spacer()
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Example 2: Unlimited Export Placeholder

struct UnlimitedExportPlaceholder: View {
    @StateObject private var paywallService = PaywallService.shared
    
    var body: some View {
        ZStack {
            AuroraBackground()
            
            VStack(spacing: 32) {
                Spacer()
                
                // Icon and title
                VStack(spacing: 16) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 80))
                        .foregroundStyle(.white)
                    
                    Text("Unlimited Export")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                }
                
                // Description
                VStack(spacing: 12) {
                    Text("Export unlimited words to CSV files")
                        .font(.title3)
                        .foregroundStyle(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                    
                    Text("Free users can export up to 50 words")
                        .font(.body)
                        .foregroundStyle(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 32)
                
                Spacer()
                
                // Action buttons
                VStack(spacing: 16) {
                    Button {
                        paywallService.presentPaywall(for: .unlimitedExport) { didSubscribe in
                            if didSubscribe {
                                print("User subscribed for unlimited export")
                            }
                        }
                    } label: {
                        Text("Upgrade to Pro")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal, 32)
                    
                    Button("Export 50 words") {
                        // Handle limited export
                    }
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.6))
                }
                
                Spacer()
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Example 3: Shared Dictionaries Placeholder

struct SharedDictionariesPlaceholder: View {
    @StateObject private var paywallService = PaywallService.shared
    
    var body: some View {
        ZStack {
            AuroraBackground()
            
            VStack(spacing: 32) {
                Spacer()
                
                // Icon and title
                VStack(spacing: 16) {
                    Image(systemName: "person.3")
                        .font(.system(size: 80))
                        .foregroundStyle(.white)
                    
                    Text("Shared Dictionaries")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                }
                
                // Description
                VStack(spacing: 12) {
                    Text("Create and manage shared dictionaries with others")
                        .font(.title3)
                        .foregroundStyle(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                    
                    Text("Collaborate on vocabulary with friends and family")
                        .font(.body)
                        .foregroundStyle(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 32)
                
                Spacer()
                
                // Action buttons
                VStack(spacing: 16) {
                    Button {
                        paywallService.presentPaywall(for: .createSharedDictionaries) { didSubscribe in
                            if didSubscribe {
                                print("User subscribed for shared dictionaries")
                            }
                        }
                    } label: {
                        Text("Upgrade to Pro")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal, 32)
                    
                    Button("Join existing dictionary") {
                        // Handle joining existing dictionaries
                    }
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.6))
                }
                
                Spacer()
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Example 4: Advanced Analytics Placeholder

struct AdvancedAnalyticsPlaceholder: View {
    @StateObject private var paywallService = PaywallService.shared
    
    var body: some View {
        ZStack {
            AuroraBackground()
            
            VStack(spacing: 32) {
                Spacer()
                
                // Icon and title
                VStack(spacing: 16) {
                    Image(systemName: "chart.bar")
                        .font(.system(size: 80))
                        .foregroundStyle(.white)
                    
                    Text("Advanced Analytics")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                }
                
                // Description
                VStack(spacing: 12) {
                    Text("Get detailed insights into your learning progress")
                        .font(.title3)
                        .foregroundStyle(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                    
                    Text("Track your vocabulary growth with advanced metrics")
                        .font(.body)
                        .foregroundStyle(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 32)
                
                Spacer()
                
                // Action buttons
                VStack(spacing: 16) {
                    Button {
                        paywallService.presentPaywall(for: .advancedAnalytics) { didSubscribe in
                            if didSubscribe {
                                print("User subscribed for advanced analytics")
                            }
                        }
                    } label: {
                        Text("Upgrade to Pro")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal, 32)
                    
                    Button("View basic stats") {
                        // Handle basic analytics
                    }
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.6))
                }
                
                Spacer()
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Example 5: General Pro Upgrade Placeholder

struct GeneralProUpgradePlaceholder: View {
    @StateObject private var paywallService = PaywallService.shared
    
    var body: some View {
        ZStack {
            AuroraBackground()
            
            VStack(spacing: 32) {
                Spacer()
                
                // Icon and title
                VStack(spacing: 16) {
                    Image(systemName: "crown")
                        .font(.system(size: 80))
                        .foregroundStyle(.white)
                    
                    Text("Unlock All Pro Features")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                }
                
                // Feature list
                VStack(spacing: 12) {
                    ForEach(SubscriptionFeature.allCases, id: \.self) { feature in
                        HStack(spacing: 12) {
                            Image(systemName: feature.icon)
                                .font(.title3)
                                .foregroundStyle(.white)
                                .frame(width: 24)
                            
                            Text(feature.displayName)
                                .font(.body)
                                .foregroundStyle(.white.opacity(0.9))
                            
                            Spacer()
                            
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .padding(.horizontal, 32)
                
                Spacer()
                
                // Action buttons
                VStack(spacing: 16) {
                    Button {
                        paywallService.presentPaywall(for: .general) { didSubscribe in
                            if didSubscribe {
                                print("User subscribed for Pro")
                            }
                        }
                    } label: {
                        Text("Upgrade to Pro")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal, 32)
                    
                    Button("Maybe Later") {
                        // Handle dismissal
                    }
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.6))
                }
                
                Spacer()
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Preview

struct ProFeatureExamples_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            GoogleSyncPlaceholder()
                .previewDisplayName("Google Sync")
            
            UnlimitedExportPlaceholder()
                .previewDisplayName("Unlimited Export")
            
            SharedDictionariesPlaceholder()
                .previewDisplayName("Shared Dictionaries")
            
            AdvancedAnalyticsPlaceholder()
                .previewDisplayName("Advanced Analytics")
            
            GeneralProUpgradePlaceholder()
                .previewDisplayName("General Pro Upgrade")
        }
    }
}
