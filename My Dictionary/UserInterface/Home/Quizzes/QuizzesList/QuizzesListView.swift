//
//  QuizzesListView.swift
//  My Dictionary
//
//  Created by Alexander Riakhin on 8/9/25.
//

import SwiftUI

struct QuizzesListView: View {
    
    typealias ViewModel = QuizzesListViewModel
    
    @ObservedObject private var viewModel: ViewModel
    @StateObject private var navigationManager: TabManager = .shared
    @StateObject private var quizWordsProvider: QuizWordsProvider = .shared
    @AppStorage(UDKeys.practiceWordCount) private var practiceWordCount: Double = 10
    
    init(viewModel: ViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            
            if viewModel.showingHardWordsOnly {
                // Show quizzes when hard words mode is enabled, even with just one hard word
                if viewModel.filteredWords.count >= 1 {
                    quizzesList
                } else {
                    insufficientHardWordsPlaceholder
                }
            } else if viewModel.hasEnoughWords {
                // Show quizzes when user has enough words
                quizzesList
            } else {
                // Show encouraging placeholder for users with < 10 words
                insufficientWordsPlaceholder
            }
        }
        .navigation(
            title: "Quizzes",
            mode: .large,
            trailingContent: {
                dictionaryPicker
            }
        )
        .onAppear {
            AnalyticsService.shared.logEvent(.quizzesOpened)
        }
    }
    
    private var dictionaryPicker: some View {
        HeaderButtonMenu(
            text: viewModel.selectedDictionary.name,
            icon: viewModel.selectedDictionary.icon
        ) {
            ForEach(viewModel.availableDictionaries) { dictionary in
                Button {
                    viewModel.handle(.dictionarySelected(dictionary))
                } label: {
                    HStack {
                        Image(systemName: dictionary.icon)
                        Text(dictionary.name)
                        Spacer()
                        Text("\(dictionary.wordCount)")
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
    
    private var quizzesList: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Quiz Types Section
                CustomSectionView(
                    header: "Quiz Types",
                    footer: "You can practice your own vocabulary, or select a shared dictionary that is already populated with words."
                ) {
                    VStack(spacing: 8) {
                        Button {
                            viewModel.output.send(.showSpellingQuiz(wordCount: Int(practiceWordCount), hardWordsOnly: viewModel.showingHardWordsOnly))
                        } label: {
                            QuizCardView(quiz: .spelling)
                        }
                        .buttonStyle(.plain)
                        .clippedWithPaddingAndBackground(
                            Color(.tertiarySystemGroupedBackground),
                            cornerRadius: 16
                        )
                        
                        Button {
                            viewModel.output.send(.showChooseDefinitionQuiz(wordCount: Int(practiceWordCount), hardWordsOnly: viewModel.showingHardWordsOnly))
                        } label: {
                            QuizCardView(quiz: .chooseDefinition)
                        }
                        .buttonStyle(.plain)
                        .clippedWithPaddingAndBackground(
                            Color(.tertiarySystemGroupedBackground),
                            cornerRadius: 16
                        )
                    }
                    .padding(.bottom, 12)
                }
                
                // Practice Settings Section
                if viewModel.words.count >= 20 {
                    CustomSectionView(
                        header: "Practice Settings",
                        footer: "Configure your quiz experience"
                    ) {
                        VStack(spacing: 8) {
                            // Hard Words Toggle
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Practice Hard Words Only")
                                        .font(.body)
                                        .fontWeight(.medium)
                                    Text(
                                        viewModel.hasHardWords
                                        ? "Focus on words that need review"
                                        : "Not enough words to review yet"
                                    )
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                }
                                
                                Spacer()
                                
                                Toggle("", isOn: $viewModel.showingHardWordsOnly)
                                    .labelsHidden()
                                    .disabled(!viewModel.hasHardWords)
                            }
                            .clippedWithPaddingAndBackground(
                                Color(.tertiarySystemGroupedBackground),
                                cornerRadius: 16
                            )
                            
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
                                        .foregroundStyle(.accent)
                                }
                                
                                let availableWords = viewModel.showingHardWordsOnly ? viewModel.filteredWords : viewModel.words
                                let maxWords = min(50, max(10, availableWords.count))
                                let minWords = 10
                                let subtitle = "Number of words to practice in each session (10-\(maxWords))"
                                
                                Text(subtitle)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                
                                Slider(value: $practiceWordCount, in: Double(minWords)...Double(maxWords), step: 1)
                                
                                HStack {
                                    Text("\(minWords)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                    Text("\(maxWords)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .clippedWithPaddingAndBackground(
                                Color(.tertiarySystemGroupedBackground),
                                cornerRadius: 16
                            )
                        }
                        .padding(.bottom, 12)
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }
    
    private var insufficientWordsPlaceholder: some View {
        VStack(spacing: 24) {
            Spacer()
            
            VStack(spacing: 16) {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 60))
                    .foregroundStyle(.accent.gradient)
                
                if case .sharedDictionary(let dictionary) = viewModel.selectedDictionary {
                    Text("Shared Dictionary Needs More Words!")
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                } else {
                    Text(viewModel.words.isEmpty ? "Start Building Your Vocabulary!" : "Keep Adding Words!")
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                }
                
                Text(viewModel.insufficientWordsMessage)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .padding(.horizontal, 32)
            
            VStack(spacing: 12) {
                if case .sharedDictionary(let dictionary) = viewModel.selectedDictionary {
                    // For shared dictionaries, show different actions
                    ActionButton(
                        "Add Words to Shared Dictionary",
                        systemImage: "plus.circle.fill",
                        style: .borderedProminent
                    ) {
                        viewModel.output.send(.showSharedDictionary(dictionary))
                    }

                    Text("Ask the dictionary owner to add more words, or switch to a different dictionary!")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                } else {
                    // For private dictionary, show the original actions
                    ActionButton(
                        viewModel.words.isEmpty ? "Add Your First Word" : "Add More Words",
                        systemImage: "plus.circle.fill",
                        style: .borderedProminent
                    ) {
                        navigationManager.switchToTab(.words)
                    }

                    Text(viewModel.words.isEmpty ?
                         "Quizzes help you test your knowledge and reinforce learning!" :
                            "You're \(10 - viewModel.words.count) words away from unlocking quizzes!")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, 32)
            
            Spacer()
        }
    }
    
    private var insufficientHardWordsPlaceholder: some View {
        VStack(spacing: 24) {
            Spacer()
            
            VStack(spacing: 16) {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 60))
                    .foregroundStyle(.accent.gradient)
                
                if case .sharedDictionary(let dictionary) = viewModel.selectedDictionary {
                    Text("Shared Dictionary Needs Hard Words!")
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                } else {
                    Text("Keep Adding Hard Words!")
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                }
                
                Text(viewModel.insufficientWordsMessage)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .padding(.horizontal, 32)
            
            VStack(spacing: 12) {
                if case .sharedDictionary(let dictionary) = viewModel.selectedDictionary {
                    Button {
                        viewModel.output.send(.showSharedDictionary(dictionary))
                    } label: {
                        Label("Add Words to Shared Dictionary", systemImage: "plus.circle.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.accent.gradient)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    
                    Text("Ask the dictionary owner to add more words, or practice some words incorrectly to create hard words!")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                } else {
                    Button {
                        navigationManager.switchToTab(.words)
                    } label: {
                        Label("Add Hard Words", systemImage: "plus.circle.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.accent.gradient)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    
                    Text("Answer some words incorrectly to create hard words for practice!")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, 32)
            
            Spacer()
        }
    }
}
