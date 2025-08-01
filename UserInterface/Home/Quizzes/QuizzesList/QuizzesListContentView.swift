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

    init(viewModel: ViewModel) {
        self._viewModel = ObservedObject(wrappedValue: viewModel)
    }

    var body: some View {
        List {
            Section {
                ForEach(Quiz.allCases) { quiz in
                    Button {
                        viewModel.handle(.showQuiz(quiz))
                        HapticManager.shared.triggerSelection()
                    } label: {
                        HStack(spacing: 8) {
                            Text(quiz.title)
                                .foregroundColor(.primary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Image(systemName: "chevron.right")
                                .frame(sideLength: 12)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            } footer: {
                Text("All words are from your list.")
            }
        }
        .listStyle(.insetGrouped)
        .onAppear {
            AnalyticsService.shared.logEvent(.quizzesOpened)
        }
    }


}
