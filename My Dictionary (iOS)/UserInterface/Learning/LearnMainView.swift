//
//  LearnMainView.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/9/25.
//

import SwiftUI
import Flow

struct LearnMainView: View {
    @StateObject private var viewModel = LearnMainViewModel()
    @State private var showingOnboarding = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Welcome Header
                welcomeHeader
                
                // Daily Progress
                dailyProgressSection
                
                // Today's Lessons
                todaysLessonsSection
                
                // Personalized Recommendations
                personalizedRecommendationsSection
                
                // Learning Statistics
                learningStatisticsSection
                
                // Quick Learning Actions
                quickLearningActionsSection
            }
            .padding(.horizontal, 16)
        }
        .groupedBackground()
        .navigation(
            title: Loc.Learning.Tabbar.learn,
            mode: .large,
            showsBackButton: false
        )
        .onAppear {
            viewModel.loadUserProfile()
        }
        .sheet(isPresented: $showingOnboarding) {
            LearningOnboardingView()
        }
    }
    
    // MARK: - Welcome Header
    
    private var welcomeHeader: some View {
        CustomSectionView(header: "Welcome Back!") {
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(viewModel.welcomeMessage)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text(viewModel.learningGoalDescription)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Learning streak
                    VStack(spacing: 4) {
                        Text("\(viewModel.learningStreak)")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.accent)
                        
                        Text("Day Streak")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.accent.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                
                // Progress towards next level
                if let nextLevelProgress = viewModel.nextLevelProgress {
                    VStack(spacing: 8) {
                        HStack {
                            Text("Progress to \(nextLevelProgress.nextLevel.displayName)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Text("\(Int(nextLevelProgress.progress * 100))%")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.accent)
                        }
                        
                        ProgressView(value: nextLevelProgress.progress)
                            .progressViewStyle(LinearProgressViewStyle(tint: .accent))
                    }
                }
            }
            .padding(.vertical, 16)
        }
    }
    
    // MARK: - Daily Learning Progress
    
    private var dailyProgressSection: some View {
        CustomSectionView(header: "Today's Learning Progress") {
            HStack(spacing: 20) {
                // Lessons learned
                ProgressCard(
                    icon: "book.fill",
                    title: "Lessons",
                    completed: viewModel.todaysStats.lessonsCompleted,
                    total: viewModel.todaysStats.lessonsGoal,
                    color: .blue
                )
                
                // New words learned
                ProgressCard(
                    icon: "plus.circle.fill",
                    title: "New Words",
                    completed: viewModel.todaysStats.wordsLearned,
                    total: viewModel.todaysStats.wordsGoal,
                    color: .green
                )
                
                // Learning time
                ProgressCard(
                    icon: "brain.head.profile",
                    title: "Study Time",
                    completed: viewModel.todaysStats.minutesSpent,
                    total: viewModel.todaysStats.timeGoal,
                    color: .orange,
                    unit: "min"
                )
            }
            .padding(.vertical, 16)
        }
    }
    
    // MARK: - Today's Lessons
    
    private var todaysLessonsSection: some View {
        CustomSectionView(header: "Today's Lessons") {
            VStack(spacing: 12) {
                ForEach(viewModel.todaysLessons, id: \.id) { lesson in
                    LessonCard(
                        lesson: lesson,
                        onStart: {
                            // TODO: Start lesson
                        }
                    )
                }
                
                if viewModel.todaysLessons.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "book.closed")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)
                        
                        Text("No learning lessons scheduled for today")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        ActionButton(
                            "Start Learning",
                            systemImage: "graduationcap.fill",
                            style: .borderedProminent
                        ) {
                            // TODO: Start learning
                        }
                    }
                    .padding(.vertical, 20)
                }
            }
            .padding(.vertical, 8)
        }
    }
    
    // MARK: - Personalized Recommendations
    
    private var personalizedRecommendationsSection: some View {
        CustomSectionView(header: "Recommended for You") {
            VStack(spacing: 12) {
                ForEach(viewModel.recommendations, id: \.id) { recommendation in
                    RecommendationCard(
                        recommendation: recommendation,
                        onTap: {
                            // TODO: Handle recommendation tap
                        }
                    )
                }
            }
            .padding(.vertical, 8)
        }
    }
    
    // MARK: - Learning Statistics
    
    private var learningStatisticsSection: some View {
        CustomSectionView(header: "Your Learning Journey") {
            VStack(spacing: 16) {
                // Weekly progress chart
                WeeklyProgressChart(data: viewModel.weeklyProgress)
                
                // Learning stats
                HStack(spacing: 16) {
                    StatCard(
                        title: "Words Learned",
                        value: "\(viewModel.totalWordsLearned)",
                        icon: "plus.circle.fill",
                        color: .blue
                    )
                    
                    StatCard(
                        title: "Lessons Learned",
                        value: "\(viewModel.totalLessonsCompleted)",
                        icon: "graduationcap.fill",
                        color: .green
                    )
                    
                    StatCard(
                        title: "Study Hours",
                        value: "\(viewModel.totalStudyHours)h",
                        icon: "brain.head.profile",
                        color: .orange
                    )
                }
            }
            .padding(.vertical, 8)
        }
    }
    
    // MARK: - Quick Learning Actions
    
    private var quickLearningActionsSection: some View {
        CustomSectionView(header: "Quick Learning") {
            HFlow(alignment: .top, spacing: 12) {
                QuickLearningCard(
                    title: "New Vocabulary",
                    icon: "plus.circle.fill",
                    color: .blue
                ) {
                    // TODO: Start vocabulary lesson
                }
                
                QuickLearningCard(
                    title: "Grammar Rules",
                    icon: "textformat.abc",
                    color: .green
                ) {
                    // TODO: Start grammar lesson
                }
                
                QuickLearningCard(
                    title: "Conversation",
                    icon: "bubble.left.and.bubble.right.fill",
                    color: .purple
                ) {
                    // TODO: Start conversation lesson
                }
                
                QuickLearningCard(
                    title: "Pronunciation",
                    icon: "speaker.wave.2.fill",
                    color: .orange
                ) {
                    // TODO: Start pronunciation lesson
                }
                
                QuickLearningCard(
                    title: "Reading",
                    icon: "book.fill",
                    color: .indigo
                ) {
                    // TODO: Start reading lesson
                }
                
                QuickLearningCard(
                    title: "Writing",
                    icon: "pencil.circle.fill",
                    color: .teal
                ) {
                    // TODO: Start writing lesson
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 8)
        }
    }
}

// MARK: - Supporting Views

extension LearnMainView {
    struct ProgressCard: View {
        let icon: String
        let title: String
        let completed: Int
        let total: Int
        let color: Color
        var unit: String = ""

        var progress: Double {
            guard total > 0 else { return 0 }
            return Double(completed) / Double(total)
        }

        var body: some View {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)

                VStack(spacing: 4) {
                    Text("\(completed)\(unit)")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)

                    Text("of \(total)\(unit)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                ProgressView(value: progress)
                    .progressViewStyle(LinearProgressViewStyle(tint: color))
                    .frame(height: 4)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(color.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    struct StatCard: View {
        let title: String
        let value: String
        let icon: String
        let color: Color

        var body: some View {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)

                Text(value)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(color.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    struct QuickLearningCard: View {
        let title: String
        let icon: String
        let color: Color
        let action: () -> Void

        var body: some View {
            Button(action: action) {
                VStack(spacing: 8) {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(color)

                    Text(title)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                }
                .frame(width: 80, height: 80)
                .background(color.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
        }
    }
}

#Preview {
    LearnMainView()
}
