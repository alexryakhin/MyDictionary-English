//
//  QuizzesListView.swift
//  My Dictionary
//
//  Created by Alexander Riakhin on 8/9/25.
//

import SwiftUI

struct QuizzesListView: View {

    @StateObject private var viewModel = QuizzesListViewModel()
    @StateObject private var sideBarManager = SideBarManager.shared
    @AppStorage(UDKeys.practiceItemCount) private var practiceItemCount: Int = 10

    var body: some View {
        ZStack {
            Color.systemGroupedBackground
                .ignoresSafeArea()

            if viewModel.hasEnoughTotalItems {
                if viewModel.hasEnoughItems {
                    quizzesList
                } else if viewModel.hasActiveFilters {
                    filtersInsufficientWordsPlaceholder
                } else {
                    insufficientItemsPlaceholder
                }
            } else {
                insufficientItemsPlaceholder
            }
        }
        .navigationTitle(Loc.Navigation.Tabbar.quizzes)
        .toolbarTitleDisplayMode(.inlineLarge)
        .toolbar {
            if viewModel.availableDictionaries.count > 1 {
                ToolbarItem(placement: .primaryAction) {
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
                    .help(Loc.Quizzes.selectDictionary)
                    .hideIfOffline()
                }
            }
        }
        .onAppear {
            AnalyticsService.shared.logEvent(.quizzesOpened)
            QuizItemsProvider.shared.refreshAvailableDictionaries()
        }
    }

    private var quizzesList: some View {
        ScrollView {
            VStack(spacing: 12) {
                // Quiz Types Section
                CustomSectionView(
                    header: Loc.Quizzes.quizTypes,
                    footer: Loc.Quizzes.youCanPracticeVocabulary
                ) {
                    VStack(spacing: 8) {
                        ForEach(Quiz.quizCases, id: \.self) { quiz in
                            Button {
                                let preset: QuizPreset = .init(
                                    itemCount: practiceItemCount,
                                    hardItemsOnly: viewModel.showingHardItemsOnly,
                                    mode: .all
                                )
                                switch quiz {
                                case .spelling:
                                    sideBarManager.selectedQuiz = .spelling(preset)
                                case .chooseDefinition:
                                    sideBarManager.selectedQuiz = .chooseDefinition(preset)
                                case .sentenceWriting:
                                    sideBarManager.selectedQuiz = .sentenceWriting(preset)
                                case .contextMultipleChoice:
                                    sideBarManager.selectedQuiz = .contextMultipleChoice(preset)
                                case .fillInTheBlank:
                                    sideBarManager.selectedQuiz = .fillInTheBlank(preset)
                                case .storyLab:
                                    // Create default config - will show configuration view since savedWords and customText are nil
                                    let config = StoryLabConfig(
                                        savedWords: nil,
                                        customText: nil,
                                        targetLanguage: viewModel.selectedLanguage ?? .english,
                                        cefrLevel: .b1,
                                        pageCount: 1
                                    )
                                    sideBarManager.selectedQuiz = .storyLab(config)
                                }
                            } label: {
                                QuizCardView(quiz: quiz)
                            }
                            .buttonStyle(.plain)
                            .clippedWithPaddingAndBackground(
                                Color.tertiarySystemGroupedBackground,
                                in: .rect(cornerRadius: 16)
                            )
                            .if(quiz.isOnlineQuiz) {
                                $0.hideIfOffline()
                            }
                            .overlay(alignment: .topTrailing) {
                                if quiz.isNewQuiz {
                                    TagView(
                                        text: Loc.Quizzes.newBadge,
                                        systemImage: "sparkles",
                                        color: quiz.color,
                                        style: .selected
                                    )
                                    .offset(x: 8, y: -4)
                                }
                            }
                        }
                    }
                    .padding(.bottom, 12)
                }

                // Practice Settings Section
                if viewModel.items.count >= 20 {
                    CustomSectionView(
                        header: Loc.Quizzes.practiceSettings,
                        footer: Loc.Quizzes.configureQuizExperience
                    ) {
                        VStack(spacing: 8) {
                            // Hard Items Toggle
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(Loc.Quizzes.practiceHardWordsOnly)
                                        .font(.body)
                                        .fontWeight(.medium)
                                    Text(
                                        viewModel.hasHardItems
                                        ? Loc.Quizzes.focusWordsNeedReview
                                        : Loc.Quizzes.notEnoughWordsReview
                                    )
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                }

                                Spacer()

                                Toggle("", isOn: $viewModel.showingHardItemsOnly)
                                    .labelsHidden()
                                    .disabled(!viewModel.hasHardItems)
                            }
                            .clippedWithPaddingAndBackground(
                                Color.tertiarySystemGroupedBackground,
                                in: .rect(cornerRadius: 16)
                            )

                            // Language Filter
                            if viewModel.availableLanguages.count > 1 {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack(spacing: 8) {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(Loc.FilterDisplay.language)
                                                .font(.body)
                                                .fontWeight(.medium)
                                            Text(Loc.Quizzes.Filters.practiceWordsSpecificLanguage)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)

                                        HeaderButtonMenu(viewModel.selectedLanguage?.displayName ?? Loc.Tts.Filters.allLanguages, size: .small) {
                                            Button(Loc.Tts.Filters.allLanguages) {
                                                viewModel.handle(.languageSelected(nil))
                                            }

                                            ForEach(viewModel.availableLanguages, id: \.self) { language in
                                                Button(language.displayName) {
                                                    viewModel.handle(.languageSelected(language))
                                                }
                                            }
                                        }
                                    }
                                }
                                .clippedWithPaddingAndBackground(
                                    Color.tertiarySystemGroupedBackground,
                                    in: .rect(cornerRadius: 16)
                                )
                            }

                            // Item Count Slider
                            VStack(alignment: .leading, spacing: 8) {
                                let availableItems = viewModel.showingHardItemsOnly ? viewModel.filteredItems : viewModel.items
                                let maxItems = min(50, max(10, availableItems.count))
                                let minItems = 10
                                let subtitle = Loc.Quizzes.numberWordsPracticeSession(minItems, maxItems)


                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(Loc.Quizzes.wordsPerSession)
                                            .font(.body)
                                            .fontWeight(.medium)
                                        Text(subtitle)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }

                                    Spacer()

                                    Text("\(Int(practiceItemCount))")
                                        .font(.body)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(.accent)
                                    Stepper(Loc.Quizzes.QuizActions.numberOfWords, value: $practiceItemCount, in: minItems...maxItems, step: 1)
                                        .labelsHidden()
                                }
                            }
                            .clippedWithPaddingAndBackground(
                                Color.tertiarySystemGroupedBackground,
                                in: .rect(cornerRadius: 16)
                            )
                        }
                        .padding(.bottom, 12)
                    }
                }
            }
            .padding(12)
        }
    }

    private var insufficientItemsPlaceholder: some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 16) {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 60))
                    .foregroundStyle(.accent.gradient)

                if case .sharedDictionary(let dictionary) = viewModel.selectedDictionary {
                    Text(Loc.Quizzes.sharedDictionaryNeedsMoreWords)
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                } else {
                    Text(
                        viewModel.items.isEmpty
                        ? Loc.Quizzes.startBuildingVocabulary
                        : Loc.Quizzes.keepAddingWords
                    )
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                }

                Text(viewModel.insufficientItemsMessage)
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
                        Loc.Quizzes.addWordsToSharedDictionary,
                        systemImage: "plus.circle.fill",
                        style: .borderedProminent
                    ) {
                        SideBarManager.shared.selectedTab = .sharedDictionary(dictionary)
                    }

                    Text(Loc.Quizzes.askDictionaryOwnerAddWords)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                } else {
                    // For private dictionary, show the original actions
                    ActionButton(
                        viewModel.items.isEmpty ? Loc.Words.addYourFirstWord : Loc.Words.addMoreWords,
                        systemImage: "plus.circle.fill",
                        style: .borderedProminent
                    ) {
                        SideBarManager.shared.selectedTab = .myDictionary
                    }

                    Text(viewModel.items.isEmpty ?
                         Loc.Quizzes.QuizList.quizzesHelpTestKnowledge :
                            Loc.Quizzes.QuizList.wordsAwayFromUnlockingQuizzes(10 - viewModel.items.count))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, 32)

            Spacer()
        }
    }
    
    private var filtersInsufficientWordsPlaceholder: some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 16) {
                Image(systemName: "line.3.horizontal.decrease")
                    .font(.system(size: 60))
                    .foregroundStyle(.accent.gradient)

                Text(Loc.Quizzes.Filters.notEnoughWordsCurrentFilters)
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                Text(viewModel.filtersInsufficientItemsMessage)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 32)

            VStack(spacing: 12) {
                // Option 1: Add more words
                ActionButton(
                    Loc.Words.addMoreWords,
                    systemImage: "plus.circle.fill",
                    style: .borderedProminent
                ) {
                    SideBarManager.shared.selectedTab = .myDictionary
                }

                // Option 2: Reset all filters
                ActionButton(
                    Loc.Quizzes.Filters.resetAllFilters,
                    systemImage: "line.3.horizontal.decrease",
                    style: .bordered
                ) {
                    viewModel.handle(.resetAllFilters)
                }

                Text(Loc.Quizzes.Filters.addMoreWordsOrReset)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 32)

            Spacer()
        }
    }
}
