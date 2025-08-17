//
//  QuizzesListView.swift
//  My Dictionary
//
//  Created by Alexander Riakhin on 8/9/25.
//

import SwiftUI

struct QuizzesListView: View {
        
    @StateObject private var viewModel = QuizzesListViewModel()
    @StateObject private var quizWordsProvider: QuizWordsProvider = .shared
    @StateObject private var sideBarManager = SideBarManager.shared
    @AppStorage(UDKeys.practiceWordCount) private var practiceWordCount: Int = 10

    var body: some View {
        ZStack {
            Color.systemGroupedBackground
                .ignoresSafeArea()
            
            if viewModel.hasEnoughWords {
                quizzesList
            } else {
                insufficientWordsPlaceholder
            }
        }
        .navigationTitle(Loc.TabBar.quizzes.localized)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                // Dictionary picker
                Menu {
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
                } label: {
                    HStack {
                        Image(systemName: viewModel.selectedDictionary.icon)
                        Text(viewModel.selectedDictionary.name)
                    }
                }
                .help(Loc.Quizzes.selectDictionary.localized)
            }
        }
        .onAppear {
            AnalyticsService.shared.logEvent(.quizzesOpened)
        }
    }
    
    private var quizzesList: some View {
        ScrollView {
            VStack(spacing: 12) {
                // Quiz Types Section
                CustomSectionView(
                    header: Loc.Quizzes.quizTypes.localized,
                    footer: Loc.Quizzes.youCanPracticeVocabulary.localized
                ) {
                    VStack(spacing: 8) {
                        Button {
                            sideBarManager.selectedQuiz = .spelling(
                                .init(
                                    wordCount: practiceWordCount,
                                    hardWordsOnly: viewModel.showingHardWordsOnly
                                )
                            )
                        } label: {
                            QuizCardView(quiz: .spelling)
                        }
                        .buttonStyle(.plain)
                        .clippedWithPaddingAndBackground(
                            Color.tertiarySystemGroupedBackground,
                            cornerRadius: 16
                        )
                        
                        Button {
                            sideBarManager.selectedQuiz = .chooseDefinition(
                                .init(
                                    wordCount: practiceWordCount,
                                    hardWordsOnly: viewModel.showingHardWordsOnly
                                )
                            )
                        } label: {
                            QuizCardView(quiz: .chooseDefinition)
                        }
                        .buttonStyle(.plain)
                        .clippedWithPaddingAndBackground(
                            Color.tertiarySystemGroupedBackground,
                            cornerRadius: 16
                        )
                    }
                    .padding(.bottom, 12)
                }
                
                // Practice Settings Section
                if viewModel.words.count >= 20 {
                    CustomSectionView(
                        header: Loc.Quizzes.practiceSettings.localized,
                        footer: Loc.Quizzes.configureQuizExperience.localized
                    ) {
                        VStack(spacing: 8) {
                            // Hard Words Toggle
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(Loc.Quizzes.practiceHardWordsOnly.localized)
                                        .font(.body)
                                        .fontWeight(.medium)
                                    Text(
                                        viewModel.hasHardWords
                                        ? Loc.Quizzes.focusWordsNeedReview.localized
                                        : Loc.Quizzes.notEnoughWordsReview.localized
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
                                Color.tertiarySystemGroupedBackground,
                                cornerRadius: 16
                            )
                            
                            // Word Count Slider
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text(Loc.Quizzes.wordsPerSession.localized)
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
                                let subtitle = Loc.Quizzes.numberWordsPracticeSession.localized(minWords, maxWords)
                                
                                Text(subtitle)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                
                                Stepper("Number of words", value: $practiceWordCount, in: minWords...maxWords, step: 1)
                                    .labelsHidden()

                                HStack {
                                    Text(Loc.Quizzes.minWords.localized(minWords))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                    Text(Loc.Quizzes.maxWords.localized(maxWords))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .clippedWithPaddingAndBackground(
                                Color.tertiarySystemGroupedBackground,
                                cornerRadius: 16
                            )
                        }
                        .padding(.bottom, 12)
                    }
                }
            }
            .padding(12)
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
                    Text(Loc.Quizzes.sharedDictionaryNeedsMoreWords.localized)
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                } else {
                    Text(viewModel.words.isEmpty ? Loc.Quizzes.startBuildingVocabulary.localized : Loc.Quizzes.keepAddingWords.localized)
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
                        Loc.Quizzes.addWordsToSharedDictionary.localized,
                        systemImage: "plus.circle.fill",
                        style: .borderedProminent
                    ) {
                        SideBarManager.shared.selectedTab = .sharedDictionary(dictionary)
                    }

                    Text(Loc.Quizzes.askDictionaryOwnerAddWords.localized)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                } else {
                    // For private dictionary, show the original actions
                    ActionButton(
                        viewModel.words.isEmpty ? Loc.Words.addYourFirstWord.localized : Loc.Words.addMoreWords.localized,
                        systemImage: "plus.circle.fill",
                        style: .borderedProminent
                    ) {
                        SideBarManager.shared.selectedTab = .words
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
}
