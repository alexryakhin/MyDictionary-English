//
//  QuizzesListViewModel.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import Foundation
import Combine
import SwiftUI

final class QuizzesListViewModel: BaseViewModel {

    enum Output {
        case showSpellingQuiz(QuizPreset)
        case showChooseDefinitionQuiz(QuizPreset)
        case showSentenceWritingQuiz(QuizPreset)
        case showContextMultipleChoiceQuiz(QuizPreset)
        case showFillInTheBlankQuiz(QuizPreset)
        case showSharedDictionary(SharedDictionary)
    }

    enum Input {
        case showQuiz(Quiz, QuizPreset)
        case dictionarySelected(QuizDictionary)
        case languageSelected(InputLanguage?)
        case resetAllFilters
    }

    var output = PassthroughSubject<Output, Never>()

    @Published var showingHardItemsOnly = false
    @Published var selectedDictionary: QuizDictionary = .privateDictionary

    private let quizItemsProvider: QuizItemsProvider = .shared
    private let aiService: AIService = .shared
    private var cancellables: Set<AnyCancellable> = []

    override init() {
        super.init()
        setupBindings()
    }

    func handle(_ input: Input) {
        switch input {
        case .dictionarySelected(let dictionary):
            selectedDictionary = dictionary
            quizItemsProvider.selectedDictionary = dictionary

            // If it's a shared dictionary, ensure items are loaded
            if case .sharedDictionary(let sharedDictionary) = dictionary {
                quizItemsProvider.loadItemsForSharedDictionary(sharedDictionary)
            }
        case .languageSelected(let language):
            quizItemsProvider.setSelectedLanguage(language)
        case .resetAllFilters:
            showingHardItemsOnly = false
            quizItemsProvider.setSelectedLanguage(nil)
        case .showQuiz(let quiz, let preset):
            switch quiz {
            case .spelling:
                output.send(.showSpellingQuiz(preset))
            case .chooseDefinition:
                output.send(.showChooseDefinitionQuiz(preset))
            case .sentenceWriting:
                guard aiService.canRunQuizToday(.sentenceWriting) else {
                    showQuizUnavailableAlert()
                    return
                }
                output.send(.showSentenceWritingQuiz(preset))
            case .contextMultipleChoice:
                guard aiService.canRunQuizToday(.contextMultipleChoice) else {
                    showQuizUnavailableAlert()
                    return
                }
                output.send(.showContextMultipleChoiceQuiz(preset))
            case .fillInTheBlank:
                guard aiService.canRunQuizToday(.fillInTheBlank) else {
                    showQuizUnavailableAlert()
                    return
                }
                output.send(.showFillInTheBlankQuiz(preset))
            case .storyLab, .musicLesson:
                break
            }
        }
    }

    // MARK: - Computed Properties

    var availableDictionaries: [QuizDictionary] {
        return quizItemsProvider.availableDictionaries
    }

    var availableLanguages: [InputLanguage] {
        return quizItemsProvider.availableLanguages
    }

    var selectedLanguage: InputLanguage? {
        return quizItemsProvider.selectedLanguage
    }

    var items: [any Quizable] {
        return quizItemsProvider.availableItems
    }

    var filteredItems: [any Quizable] {
        if showingHardItemsOnly {
            return items.filter { $0.difficultyLevel == .needsReview }
        }
        return items
    }

    var hasHardItems: Bool {
        return items.filter { $0.difficultyLevel == .needsReview }.count > 10
    }

    var hasEnoughTotalItems: Bool {
        // Check total items without language filtering
        let totalItems = quizItemsProvider.availableItems.count
        return totalItems >= 10
    }

    var hasEnoughItems: Bool {
        // For shared dictionaries, check if items are loaded and if there are enough
        if case .sharedDictionary(let dictionary) = selectedDictionary {
            let itemCount = quizItemsProvider.getTotalItemsCount()
            let requiredCount = showingHardItemsOnly ? 1 : 10
            return itemCount >= requiredCount
        }
        // For private dictionary, use the existing logic
        return quizItemsProvider.hasEnoughItems(itemCount: 10, hardItemsOnly: showingHardItemsOnly)
    }

    var insufficientItemsMessage: String {
        if case .sharedDictionary(let dictionary) = selectedDictionary {
            let totalItems = quizItemsProvider.getTotalItemsCount()
            if showingHardItemsOnly {
                let hardItemsCount = quizItemsProvider.getHardItemsCount()
                return Loc.Quizzes.sharedDictionaryNeedsHardWords(dictionary.name, hardItemsCount)
            } else {
                return Loc.Quizzes.needsAtLeastWordsStartQuizzes(dictionary.name, totalItems)
            }
        } else {
            // Private dictionary message
            if showingHardItemsOnly {
                let hardItemsCount = quizItemsProvider.getHardItemsCount()
                return Loc.Quizzes.needAtLeastHardWordPractice(hardItemsCount)
            } else {
                let totalItems = quizItemsProvider.getTotalItemsCount()
                return Loc.Quizzes.needAtLeastWordsStartQuizzes(totalItems)
            }
        }
    }

    var hasActiveFilters: Bool {
        return selectedLanguage != nil || showingHardItemsOnly
    }

    var activeFiltersDescription: String {
        var filters: [String] = []

        if let selectedLanguage = selectedLanguage {
            filters.append(selectedLanguage.displayName)
        }

        if showingHardItemsOnly {
            filters.append(Loc.Quizzes.Filters.hardWordsOnly)
        }

        return filters.joined(separator: " + ")
    }

    var filtersInsufficientItemsMessage: String {
        let filteredItemsCount = quizItemsProvider.getTotalItemsCount()

        if showingHardItemsOnly {
            let hardItemsCount = quizItemsProvider.getHardItemsCount()
            return Loc.Quizzes.Filters.need10HardWordsCurrentFilters(Loc.Plurals.Words.wordsCount(hardItemsCount))
        } else {
            return Loc.Quizzes.Filters.need10WordsCurrentFilters(Loc.Plurals.Words.wordsCount(filteredItemsCount))
        }
    }

    /// Fetches latest data from Core Data
    private func setupBindings() {
        // Listen to quiz items provider changes
        quizItemsProvider.$selectedDictionary
            .receive(on: RunLoop.main)
            .sink { [weak self] dictionary in
                self?.selectedDictionary = dictionary
            }
            .store(in: &cancellables)
    }

    private func showQuizUnavailableAlert() {
        Task { @MainActor in
            showAlert(
                withModel: .init(
                    title: Loc.Subscription.ProFeatures.aiQuizzes,
                    message: Loc.Subscription.ProFeatures.aiQuizzesDescription,
                    actionText: Loc.Actions.ok,
                    additionalActionText: Loc.Subscription.Paywall.upgradeToPro,
                    action: {},
                    additionalAction: {
                        PaywallService.shared.presentPaywall(for: .aiQuizzes)
                    }
                )
            )
        }
    }
}
