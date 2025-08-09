//
//  IdiomsFlow.swift
//  My Dictionary
//
//  Created by Alexander Riakhin on 8/9/25.
//

import SwiftUI

struct IdiomsFlow: View {

    // MARK: - Properties

    @Binding var navigationPath: NavigationPath
    @ObservedObject var viewModel: IdiomListViewModel

    // MARK: - Body

    var body: some View {
        IdiomListContentView(viewModel: viewModel)
            .onReceive(viewModel.output) { output in
                handleOutput(output)
            }
    }

    // MARK: - Private Methods

    private func handleOutput(_ output: IdiomListViewModel.Output) {
        switch output {
        case .showIdiomDetails(let idiom):
            navigationPath.append(idiom)
        case .showAddIdiom:
            navigationPath.append("add_idiom")
        }
    }
}
