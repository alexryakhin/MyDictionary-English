//
//  LessonCard.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/9/25.
//

import SwiftUI

struct LessonCard: View {
    let lesson: Lesson
    let onStart: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Lesson icon
            VStack {
                Image(systemName: lesson.iconName)
                    .font(.title2)
                    .foregroundColor(lesson.color)
                    .frame(width: 40, height: 40)
                    .background(lesson.color.opacity(0.1))
                    .clipShape(Circle())
            }
            
            // Lesson content
            VStack(alignment: .leading, spacing: 4) {
                Text(lesson.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(lesson.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                // Lesson metadata
                HStack(spacing: 16) {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(lesson.duration) min")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundColor(.yellow)
                        Text(lesson.difficulty.displayName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if lesson.isCompleted {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(.green)
                            Text("Completed")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    }
                }
            }
            
            Spacer()
            
            // Action button
            if lesson.isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.green)
            } else {
                HeaderButton(
                    "Start",
                    icon: "play.fill",
                    color: lesson.color,
                    size: .small,
                    style: .borderedProminent,
                    action: onStart
                )
            }
        }
        .padding(16)
        .background(Color.secondarySystemGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Lesson Model

struct Lesson: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let iconName: String
    let color: Color
    let duration: Int
    let difficulty: LessonDifficulty
    let isCompleted: Bool
    let category: LessonCategory
    
    enum LessonDifficulty {
        case beginner
        case intermediate
        case advanced
        
        var displayName: String {
            switch self {
            case .beginner: return "Beginner"
            case .intermediate: return "Intermediate"
            case .advanced: return "Advanced"
            }
        }
    }
    
    enum LessonCategory {
        case vocabulary
        case grammar
        case conversation
        case pronunciation
        case reading
        case writing
        
        var displayName: String {
            switch self {
            case .vocabulary: return "Vocabulary"
            case .grammar: return "Grammar"
            case .conversation: return "Conversation"
            case .pronunciation: return "Pronunciation"
            case .reading: return "Reading"
            case .writing: return "Writing"
            }
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        LessonCard(
            lesson: Lesson(
                title: "Basic Greetings",
                description: "Learn essential greetings and polite expressions for daily conversations",
                iconName: "hand.wave.fill",
                color: .blue,
                duration: 15,
                difficulty: .beginner,
                isCompleted: false,
                category: .conversation
            ),
            onStart: {}
        )
        
        LessonCard(
            lesson: Lesson(
                title: "Present Tense Verbs",
                description: "Master the present tense and common verb conjugations",
                iconName: "textformat.abc",
                color: .green,
                duration: 20,
                difficulty: .intermediate,
                isCompleted: true,
                category: .grammar
            ),
            onStart: {}
        )
    }
    .padding()
}
