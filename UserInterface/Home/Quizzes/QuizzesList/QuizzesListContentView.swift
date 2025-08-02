//
//  QuizzesListContentView.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import SwiftUI

struct QuizzesListContentView: View {

    typealias ViewModel = QuizzesListViewModel

    @ObservedObject var viewModel: ViewModel
    @StateObject private var navigationManager: NavigationManager = .shared
    @State private var showingHardWordsOnly = false
    @State private var practiceWordCount: Double = 10

    init(viewModel: ViewModel) {
        self._viewModel = ObservedObject(wrappedValue: viewModel)
    }

    var body: some View {
        Group {
            if viewModel.words.count >= 10 {
                // Show quizzes when user has enough words
                quizzesList
            } else {
                // Show encouraging placeholder for users with < 10 words
                insufficientWordsPlaceholder
            }
        }
        .navigationTitle("Quizzes")
        .onAppear {
            AnalyticsService.shared.logEvent(.quizzesOpened)
        }
    }

    private var quizzesList: some View {
        List {
            // Practice Settings Section
            Section {
                VStack(spacing: 16) {
                    // Hard Words Toggle
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Practice Hard Words Only")
                                .font(.body)
                                .fontWeight(.medium)
                            Text("Focus on words that need review")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Toggle("", isOn: $showingHardWordsOnly)
                            .labelsHidden()
                    }
                    
                    Divider()
                    
                    // Word Count Slider
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Words per Session")
                                .font(.body)
                                .fontWeight(.medium)
                            Spacer()
                            Text("\(Int(practiceWordCount))")
                                .font(.body)
                                .fontWeight(.semibold)
                                .foregroundColor(.blue)
                        }
                        
                        Slider(value: $practiceWordCount, in: 5...50, step: 5)
                            .accentColor(.blue)
                        
                        HStack {
                            Text("5")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("50")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.vertical, 8)
            } header: {
                Text("Practice Settings")
            } footer: {
                Text("Configure your quiz experience")
            }

            // Quiz Types Section
            Section {
                ForEach(Quiz.allCases) { quiz in
                    NavigationLink {
                        switch quiz {
                        case .spelling:
                            SpellingQuizContentView()
                        case .chooseDefinitions:
                            ChooseDefinitionQuizContentView()
                        }
                    } label: {
                        QuizCardView(quiz: quiz)
                    }
                }
            } header: {
                Text("Quiz Types")
            } footer: {
                Text("All words are from your list.")
            }
        }
        .listStyle(.insetGrouped)
    }

    private var insufficientWordsPlaceholder: some View {
        VStack(spacing: 24) {
            Spacer()
            
            VStack(spacing: 16) {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 60))
                    .foregroundStyle(.blue.gradient)
                
                Text(viewModel.words.isEmpty ? "Start Building Your Vocabulary!" : "Keep Adding Words!")
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text(viewModel.words.isEmpty ? 
                     "You need at least **10 words** in your list to start taking quizzes.\n\nCurrently you have **0 words**." :
                     "You need at least **10 words** in your list to start taking quizzes.\n\nCurrently you have **\(viewModel.words.count) words**.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .padding(.horizontal, 32)
            
            VStack(spacing: 12) {
                Button {
                    navigationManager.switchToTab(.words)
                } label: {
                    Label(viewModel.words.isEmpty ? "Add Your First Word" : "Add More Words", systemImage: "plus.circle.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.blue.gradient)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                
                Text(viewModel.words.isEmpty ? 
                     "Quizzes help you test your knowledge and reinforce learning!" :
                     "You're \(10 - viewModel.words.count) words away from unlocking quizzes!")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 32)
            
            Spacer()
        }
        .background(Color(.systemGroupedBackground))
    }
}

// MARK: - Quiz Card View
struct QuizCardView: View {
    let quiz: Quiz
    
    var body: some View {
        HStack(spacing: 16) {
            // Quiz Icon
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(quiz.color.gradient)
                    .frame(width: 50, height: 50)
                
                Image(systemName: quiz.iconName)
                    .font(.title2)
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(quiz.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(quiz.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Quiz Extensions
extension Quiz {
    var color: Color {
        switch self {
        case .spelling:
            return .blue
        case .chooseDefinitions:
            return .green
        }
    }
    
    var iconName: String {
        switch self {
        case .spelling:
            return "pencil.and.outline"
        case .chooseDefinitions:
            return "list.bullet.circle"
        }
    }
    
    var description: String {
        switch self {
        case .spelling:
            return "Test your spelling skills by typing words from definitions"
        case .chooseDefinitions:
            return "Choose the correct definition for given words"
        }
    }
}
