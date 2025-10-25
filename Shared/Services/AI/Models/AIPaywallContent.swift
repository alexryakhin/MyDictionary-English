//
//  AIPaywallContent.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/9/25.
//

import Foundation
import OpenAI

// MARK: - AI Paywall Content Models

struct AIPaywallContent: Codable, JSONSchemaConvertible {
    let title: String
    let subtitle: String
    let benefits: [AIPaywallBenefit]
    
    static let example: Self = {
        .init(
            title: "Ready to master Spanish, Alex?",
            subtitle: "Unlock AI-powered learning tools designed for your academic goals",
            benefits: [
                AIPaywallBenefit.example,
                AIPaywallBenefit(
                    feature: .wordCollections,
                    personalizedDescription: "Access curated vocabulary sets tailored to your interests"
                ),
                AIPaywallBenefit(
                    feature: .aiQuizzes,
                    personalizedDescription: "Get personalized quizzes that adapt to your learning pace"
                )
            ]
        )
    }()
}

struct AIPaywallBenefit: Codable, JSONSchemaConvertible {
    let feature: SubscriptionFeature
    let personalizedDescription: String
    
    static let example: Self = {
        .init(
            feature: .advancedAnalytics,
            personalizedDescription: "Track your progress with detailed insights and analytics"
        )
    }()
}
