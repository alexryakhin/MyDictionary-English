//
//  QuizzesListContentView.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import SwiftUI

struct QuizzesListContentView: View {

    @ObservedObject var viewModel: QuizzesListViewModel

    init(viewModel: QuizzesListViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        QuizzesListView(viewModel: viewModel)
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
        .multilineTextAlignment(.leading)
    }
}

// MARK: - Quiz Extensions
extension Quiz {
    var color: Color {
        switch self {
        case .spelling:
            return .blue
        case .chooseDefinition:
            return .green
        }
    }
    
    var iconName: String {
        switch self {
        case .spelling:
            return "pencil.and.outline"
        case .chooseDefinition:
            return "list.bullet.circle"
        }
    }
    
    var description: String {
        switch self {
        case .spelling:
            return "Test your spelling skills by typing words correctly"
        case .chooseDefinition:
            return "Select the correct definition for each word"
        }
    }
}
