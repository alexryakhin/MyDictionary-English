//
//  RecommendationCard.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/9/25.
//

import SwiftUI

struct RecommendationCard: View {
    let recommendation: Recommendation
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Recommendation icon
                VStack {
                    Image(systemName: recommendation.iconName)
                        .font(.title2)
                        .foregroundColor(recommendation.color)
                        .frame(width: 40, height: 40)
                        .background(recommendation.color.opacity(0.1))
                        .clipShape(Circle())
                }
                
                // Recommendation content
                VStack(alignment: .leading, spacing: 4) {
                    Text(recommendation.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text(recommendation.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                    
                    // Recommendation metadata
                    HStack(spacing: 12) {
                        TagView(
                            text: recommendation.category.displayName,
                            color: recommendation.color,
                            size: .mini
                        )
                        
                        if let reason = recommendation.reason {
                            HStack(spacing: 4) {
                                Image(systemName: "lightbulb.fill")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                                Text(reason)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                Spacer()
                
                // Arrow indicator
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(16)
            .background(Color.secondarySystemGroupedBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Recommendation Model

struct Recommendation: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let iconName: String
    let color: Color
    let category: RecommendationCategory
    let reason: String?
    
    enum RecommendationCategory {
        case vocabulary
        case grammar
        case conversation
        case reading
        case writing
        case listening
        case pronunciation
        
        var displayName: String {
            switch self {
            case .vocabulary: return "Vocabulary"
            case .grammar: return "Grammar"
            case .conversation: return "Conversation"
            case .reading: return "Reading"
            case .writing: return "Writing"
            case .listening: return "Listening"
            case .pronunciation: return "Pronunciation"
            }
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        RecommendationCard(
            recommendation: Recommendation(
                title: "Food & Dining Vocabulary",
                description: "Expand your vocabulary with essential words for restaurants, cooking, and dining experiences",
                iconName: "fork.knife",
                color: .orange,
                category: .vocabulary,
                reason: "Based on your interest in cooking"
            ),
            onTap: {}
        )
        
        RecommendationCard(
            recommendation: Recommendation(
                title: "Business Meeting Phrases",
                description: "Learn professional expressions and phrases commonly used in business meetings",
                iconName: "briefcase.fill",
                color: .blue,
                category: .conversation,
                reason: "Matches your career goals"
            ),
            onTap: {}
        )
        
        RecommendationCard(
            recommendation: Recommendation(
                title: "Past Tense Practice",
                description: "Strengthen your understanding of past tense verbs with interactive exercises",
                iconName: "clock.arrow.circlepath",
                color: .green,
                category: .grammar,
                reason: "You need more practice"
            ),
            onTap: {}
        )
    }
    .padding()
}
