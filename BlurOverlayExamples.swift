//
//  BlurOverlayExamples.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//
//  Examples of different blur overlay styles and usage
//

import SwiftUI

// MARK: - Example 1: Different Blur Styles

struct BlurStylesExample: View {
    @State private var selectedStyle: AnalyticsBlurStyle = .natural
    
    var body: some View {
        VStack(spacing: 20) {
            // Your analytics content
            VStack(spacing: 16) {
                Text("Analytics Dashboard")
                    .font(.title)
                    .fontWeight(.bold)
                
                // Sample chart
                RoundedRectangle(cornerRadius: 12)
                    .fill(.blue.opacity(0.3))
                    .frame(height: 200)
                    .overlay(
                        Text("Chart Data")
                            .foregroundStyle(.secondary)
                    )
                
                // Sample stats
                HStack(spacing: 16) {
                    StatCard(title: "Words", value: "150", icon: "textformat")
                    StatCard(title: "Accuracy", value: "85%", icon: "target")
                    StatCard(title: "Time", value: "2h", icon: "clock")
                }
            }
            .padding()
            .background(.background)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            
            // Blur style picker
            Picker("Blur Style", selection: $selectedStyle) {
                Text("Natural").tag(AnalyticsBlurStyle.natural)
                Text("Soft").tag(AnalyticsBlurStyle.soft)
                Text("Gradient").tag(AnalyticsBlurStyle.gradient)
                Text("Noise").tag(AnalyticsBlurStyle.noise)
            }
            .pickerStyle(.segmented)
        }
        .padding()
        .blurOverlay(
            isActive: true, // Always show for demo
            message: "Upgrade to Pro for advanced analytics",
            style: selectedStyle
        )
    }
}

// MARK: - Example 2: Conditional Blur Based on Feature

struct ConditionalBlurExample: View {
    @StateObject private var subscriptionService = SubscriptionService.shared
    
    var body: some View {
        VStack(spacing: 20) {
            // Basic analytics (always visible)
            VStack(alignment: .leading, spacing: 12) {
                Text("Basic Analytics")
                    .font(.headline)
                
                HStack {
                    StatCard(title: "Total Words", value: "150", icon: "textformat")
                    StatCard(title: "Mastered", value: "45", icon: "checkmark.circle")
                }
            }
            .padding()
            .background(.background)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            // Advanced analytics (Pro only)
            VStack(alignment: .leading, spacing: 12) {
                Text("Advanced Analytics")
                    .font(.headline)
                
                VStack(spacing: 16) {
                    // Detailed chart
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.green.opacity(0.3))
                        .frame(height: 150)
                        .overlay(
                            Text("Detailed Progress Chart")
                                .foregroundStyle(.secondary)
                        )
                    
                    // Advanced stats
                    HStack {
                        StatCard(title: "Accuracy Trend", value: "+12%", icon: "chart.line.uptrend.xyaxis")
                        StatCard(title: "Study Time", value: "2.5h", icon: "clock.fill")
                        StatCard(title: "Weaknesses", value: "3", icon: "exclamationmark.triangle")
                    }
                }
            }
            .padding()
            .background(.background)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .blurOverlay(
                isActive: !subscriptionService.canAccessAdvancedAnalytics(),
                message: "Upgrade to Pro for detailed insights and trends",
                style: .soft
            )
        }
        .padding()
    }
}

// MARK: - Example 3: Custom Blur with Different Messages

struct CustomBlurMessagesExample: View {
    @State private var showBlur = false
    @State private var blurMessage = "Upgrade to Pro"
    
    var body: some View {
        VStack(spacing: 20) {
            // Analytics content
            VStack(spacing: 16) {
                Text("Analytics Dashboard")
                    .font(.title)
                
                // Sample content
                RoundedRectangle(cornerRadius: 12)
                    .fill(.purple.opacity(0.3))
                    .frame(height: 200)
                    .overlay(
                        VStack {
                            Text("Advanced Charts")
                            Text("Detailed Insights")
                            Text("Trend Analysis")
                        }
                        .foregroundStyle(.secondary)
                    )
            }
            .padding()
            .background(.background)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            
            // Control buttons
            VStack(spacing: 12) {
                Button("Show Natural Blur") {
                    blurMessage = "Upgrade to Pro for natural blur effect"
                    showBlur = true
                }
                .buttonStyle(.bordered)
                
                Button("Show Gradient Blur") {
                    blurMessage = "Upgrade to Pro for gradient blur effect"
                    showBlur = true
                }
                .buttonStyle(.bordered)
                
                Button("Show Noise Blur") {
                    blurMessage = "Upgrade to Pro for noise-enhanced blur"
                    showBlur = true
                }
                .buttonStyle(.bordered)
                
                Button("Hide Blur") {
                    showBlur = false
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .blurOverlay(
            isActive: showBlur,
            message: blurMessage,
            style: .natural
        )
    }
}

// MARK: - Example 4: Blur with Custom Styling

struct CustomStylingBlurExample: View {
    var body: some View {
        VStack(spacing: 20) {
            // Your content
            VStack(spacing: 16) {
                Text("Premium Analytics")
                    .font(.title)
                    .fontWeight(.bold)
                
                // Premium features
                VStack(spacing: 12) {
                    FeatureRow(icon: "chart.bar.fill", title: "Advanced Charts", description: "Detailed visualizations")
                    FeatureRow(icon: "target", title: "Goal Tracking", description: "Set and monitor learning goals")
                    FeatureRow(icon: "brain.head.profile", title: "AI Insights", description: "Personalized recommendations")
                    FeatureRow(icon: "export", title: "Data Export", description: "Export your progress data")
                }
            }
            .padding()
            .background(.background)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .padding()
        .blurOverlay(
            isActive: true,
            message: "Unlock premium analytics with Pro subscription",
            style: .gradient
        )
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.accent)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Example 5: Blur with Animation

struct AnimatedBlurExample: View {
    @State private var showBlur = false
    @State private var blurOpacity: Double = 0
    
    var body: some View {
        VStack(spacing: 20) {
            // Analytics content
            VStack(spacing: 16) {
                Text("Interactive Analytics")
                    .font(.title)
                
                // Interactive chart
                RoundedRectangle(cornerRadius: 12)
                    .fill(.orange.opacity(0.3))
                    .frame(height: 200)
                    .overlay(
                        Text("Interactive Chart")
                            .foregroundStyle(.secondary)
                    )
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            showBlur.toggle()
                            blurOpacity = showBlur ? 1 : 0
                        }
                    }
            }
            .padding()
            .background(.background)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            
            Text("Tap the chart to toggle blur")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .blurOverlay(
            isActive: showBlur,
            message: "Upgrade to Pro for interactive analytics",
            style: .noise
        )
    }
}

// MARK: - Example 6: Blur with Different Opacities

struct BlurOpacityExample: View {
    @State private var blurOpacity: Double = 0.3
    
    var body: some View {
        VStack(spacing: 20) {
            // Content
            VStack(spacing: 16) {
                Text("Opacity Control")
                    .font(.title)
                
                RoundedRectangle(cornerRadius: 12)
                    .fill(.blue.opacity(0.3))
                    .frame(height: 200)
                    .overlay(
                        Text("Content with variable blur opacity")
                            .foregroundStyle(.secondary)
                    )
            }
            .padding()
            .background(.background)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            
            // Opacity slider
            VStack(alignment: .leading, spacing: 8) {
                Text("Blur Opacity: \(blurOpacity, specifier: "%.1f")")
                    .font(.caption)
                
                Slider(value: $blurOpacity, in: 0...1)
            }
            .padding(.horizontal)
        }
        .padding()
        .overlay(
            // Custom blur with variable opacity
            Rectangle()
                .fill(.ultraThinMaterial)
                .blur(radius: 20)
                .opacity(blurOpacity)
        )
    }
}

// MARK: - Preview

struct BlurOverlayExamples_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            BlurStylesExample()
                .previewDisplayName("Blur Styles")
            
            ConditionalBlurExample()
                .previewDisplayName("Conditional Blur")
            
            CustomBlurMessagesExample()
                .previewDisplayName("Custom Messages")
            
            CustomStylingBlurExample()
                .previewDisplayName("Custom Styling")
            
            AnimatedBlurExample()
                .previewDisplayName("Animated Blur")
            
            BlurOpacityExample()
                .previewDisplayName("Blur Opacity")
        }
    }
}
