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
    }

    var output = PassthroughSubject<Output, Never>()

    @Published var showingHardItemsOnly = false
    @Published var selectedDictionary: QuizDictionary = .privateDictionary

    private let quizItemsProvider: QuizItemsProvider = .shared
    private let quizUsageTracker: QuizUsageTracker = .shared
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
        case .showQuiz(let quiz, let preset):
            switch quiz {
            case .spelling:
                output.send(.showSpellingQuiz(preset))
            case .chooseDefinition:
                output.send(.showChooseDefinitionQuiz(preset))
            case .sentenceWriting:
                do {
                    guard try quizUsageTracker.canRunQuizToday(.sentenceWriting) else {
                        showQuizUnavailableAlert()
                        return
                    }
                    output.send(.showSentenceWritingQuiz(preset))
                } catch {
                    errorReceived(error)
                }
            case .contextMultipleChoice:
                do {
                    guard try quizUsageTracker.canRunQuizToday(.contextMultipleChoice) else {
                        showQuizUnavailableAlert()
                        return
                    }
                    output.send(.showContextMultipleChoiceQuiz(preset))
                } catch {
                    errorReceived(error)
                }
            case .fillInTheBlank:
                do {
                    guard try quizUsageTracker.canRunQuizToday(.fillInTheBlank) else {
                        showQuizUnavailableAlert()
                        return
                    }
                    output.send(.showFillInTheBlankQuiz(preset))
                } catch {
                    errorReceived(error)
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    var availableDictionaries: [QuizDictionary] {
        return quizItemsProvider.availableDictionaries
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
                    title: Loc.Errors.oops,
                    message: Loc.Quizzes.quizAvailableOnceADayMessage,
                    actionText: Loc.Actions.ok,
                    additionalActionText: Loc.Subscription.Paywall.upgradeToPro,
                    action: {},
                    additionalAction: {
                        PaywallService.shared.isShowingPaywall = true
                    }
                )
            )
        }
    }
}
