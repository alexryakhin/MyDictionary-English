//
//  QuizzesListContentView.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import SwiftUI
import CoreUserInterface
import CoreNavigation
import Core
import StoreKit

public struct QuizzesListContentView: PageView {

    public typealias ViewModel = QuizzesListViewModel

    @ObservedObject public var viewModel: ViewModel

    public init(viewModel: ViewModel) {
        self._viewModel = ObservedObject(wrappedValue: viewModel)
    }

    public var contentView: some View {
        List {
            Section {
                ForEach(Quiz.allCases) { quiz in
                    Button(quiz.title) {
                        viewModel.handle(.showQuiz(quiz))
                    }
                }
            } footer: {
                Text("All words are from your list.")
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(TabBarItem.quizzes.title)
    }

    public func placeholderView(props: PageState.PlaceholderProps) -> some View {
        EmptyListView(
            label: viewModel.words.isEmpty ? "No words in your list" : "Not enough words",
            description: "Add at least 10 words to your list to play!"
        )
    }
}
