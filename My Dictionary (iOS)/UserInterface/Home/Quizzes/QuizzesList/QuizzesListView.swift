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
    @StateObject private var QuizItemsProvider: QuizItemsProvider = .shared
    @AppStorage(UDKeys.practiceItemCount) private var practiceItemCount: Double = 10

    init(viewModel: ViewModel) {
        self.viewModel = viewModel
    }

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
                    insufficientWordsPlaceholder
                }
            } else {
                insufficientWordsPlaceholder
            }
        }
        .navigation(
            title: Loc.Navigation.Tabbar.quizzes,
            mode: .large,
            trailingContent: {
                if viewModel.availableDictionaries.count > 1 {
                    dictionaryPicker
                }
            }
        )
        .onAppear {
            AnalyticsService.shared.logEvent(.quizzesOpened)
        }
    }

    private var dictionaryPicker: some View {
        HeaderButtonMenu(
            viewModel.selectedDictionary.name,
            icon: viewModel.selectedDictionary.icon,
            size: .small
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
        .hideIfOffline()
        
    }

    private var quizzesList: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Quiz Types Section
                CustomSectionView(
                    header: Loc.Quizzes.QuizList.quizTypes,
                    footer: Loc.Quizzes.youCanPracticeVocabulary
                ) {
                    VStack(spacing: 8) {
                        ForEach(Quiz.quizCases, id: \.self) { quiz in
                            Button {
                                viewModel.handle(.showQuiz(quiz, .init(
                                    itemCount: Int(practiceItemCount),
                                    hardItemsOnly: viewModel.showingHardItemsOnly,
                                    mode: .all
                                )))
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
                        header: Loc.Quizzes.QuizList.practiceSettings,
                        footer: Loc.Quizzes.QuizList.configureQuizExperience
                    ) {
                        VStack(spacing: 8) {
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
                            
                            // Hard Words Toggle
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(Loc.Quizzes.practiceHardWordsOnly)
                                        .font(.body)
                                        .fontWeight(.medium)
                                    Text(
                                        viewModel.hasHardItems
                                        ? Loc.Quizzes.QuizList.focusOnWordsNeedReview
                                        : Loc.Quizzes.QuizList.notEnoughWordsReviewYet
                                    )
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                }

                                Spacer()

                                Toggle("", isOn: $viewModel.showingHardItemsOnly)
                                    .labelsHidden()
                            }
                            .clippedWithPaddingAndBackground(
                                Color.tertiarySystemGroupedBackground,
                                in: .rect(cornerRadius: 16)
                            )

                            // Word Count Slider
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text(Loc.Quizzes.wordsPerSession)
                                        .font(.body)
                                        .fontWeight(.medium)
                                    Spacer()
                                    Text("\(Int(practiceItemCount))")
                                        .font(.body)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(.accent)
                                }

                                let availableWords = viewModel.showingHardItemsOnly
                                ? viewModel.filteredItems
                                : viewModel.items
                                let maxWords = min(50, max(10, availableWords.count))
                                let minWords = 10
                                let subtitle = Loc.Quizzes.numberWordsPracticeSession(minWords, maxWords)

                                Text(subtitle)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                Slider(value: $practiceItemCount, in: Double(minWords)...Double(maxWords), step: 1)

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
                                Color.tertiarySystemGroupedBackground,
                                in: .rect(cornerRadius: 16)
                            )
                        }
                        .padding(.bottom, 12)
                    }
                }
            }
            .padding(vertical: 12, horizontal: 16)
            .if(isPad) { view in
                view
                    .frame(maxWidth: 550, alignment: .center)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
    }

    private var insufficientWordsPlaceholder: some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 16) {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 60))
                    .foregroundStyle(.accent.gradient)

                if case .sharedDictionary(_) = viewModel.selectedDictionary {
                    Text(Loc.Quizzes.sharedDictionaryNeedsMoreWords)
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                } else {
                    Text(viewModel.items.isEmpty ? Loc.Quizzes.startBuildingVocabulary : Loc.Quizzes.keepAddingWords)
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
                        Loc.Quizzes.QuizList.addWordsToSharedDictionary,
                        systemImage: "plus.circle.fill",
                        style: .borderedProminent
                    ) {
                        viewModel.output.send(.showSharedDictionary(dictionary))
                    }

                    Text(Loc.Quizzes.askDictionaryOwnerAddWordsOrSwitch)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                } else {
                    // For private dictionary, show the original actions
                    ActionButton(
                        viewModel.items.isEmpty ? Loc.Quizzes.QuizList.addYourFirstWord : Loc.Quizzes.QuizList.addMoreWords,
                        systemImage: "plus.circle.fill",
                        style: .borderedProminent
                    ) {
                        TabManager.shared.switchToTab(.myDictionary)
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
                Image(systemName: "line.3.horizontal.decrease.circle")
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
                    .lineSpacing(4)
            }
            .padding(.horizontal, 32)

            VStack(spacing: 12) {
                // Option 1: Add more words
                ActionButton(
                    Loc.Words.addMoreWords,
                    systemImage: "plus.circle.fill",
                    style: .borderedProminent
                ) {
                    TabManager.shared.switchToTab(.myDictionary)
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
